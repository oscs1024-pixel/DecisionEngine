import DecisionEngineCore
import Foundation
import MLX
import MLXLLM
import MLXLMCommon

public enum MLXDecisionEngineError: Error, Sendable {
    case modelNotLoaded
    case contextTooLong(actual: Int, maximum: Int)
    case invalidOptionCount(questionId: String, count: Int)
    case forwardPassUnavailable
}

/// Owns the Qwen3.5 model container and the checkpoint-specific decider lifecycle.
///
/// Current mlx-swift-lm exposes Qwen3.5 through LLMModelFactory and ModelContainer.
/// The actual slot-logit gather is intentionally separated from generation: decider
/// classification must read model logits, not generated text.
public actor MLXDecisionEngine: DecisionEngine {
    private var container: ModelContainer?
    private var registration: ModelRegistration?
    private let configuration: DeciderConfiguration

    public init(configuration: DeciderConfiguration = .init()) {
        self.configuration = configuration
    }

    public var isLoaded: Bool { get async { container != nil } }

    public func loadModel(configuration registration: ModelRegistration) async throws {
        let modelConfiguration: ModelConfiguration
        switch registration.location {
        case .directory(let path):
            modelConfiguration = ModelConfiguration(directory: URL(filePath: path))
        case .hub(let id):
            modelConfiguration = ModelConfiguration(id: id)
        case nil:
            modelConfiguration = ModelConfiguration(id: registration.modelId)
        }

        let loaded = try await LLMModelFactory.shared.loadContainer(
            configuration: modelConfiguration
        )
        self.container = loaded
        self.registration = registration
    }

    public func unloadModel() async {
        container = nil
        registration = nil
    }

    public func decide(
        state: DecisionState,
        questions: [DecisionQuestion]
    ) async throws -> [DecisionAnswer] {
        guard let container else { throw MLXDecisionEngineError.modelNotLoaded }
        let rendered = try PromptBuilder.decider(state: state, questions: questions)

        for slot in rendered.slots where !(2...10).contains(slot.optionNames.count) {
            throw MLXDecisionEngineError.invalidOptionCount(
                questionId: slot.questionId,
                count: slot.optionNames.count
            )
        }

        // Tokenization and label validation happen inside ModelContainer.perform so
        // tokenizer/model access stays serialized with the container.
        return try await container.perform { _, tokenizer in
            let tokenIds = tokenizer.encode(text: rendered.text)
            guard tokenIds.count <= configuration.maximumContextTokens else {
                throw MLXDecisionEngineError.contextTooLong(
                    actual: tokenIds.count,
                    maximum: configuration.maximumContextTokens
                )
            }

            _ = try SlotLocator.locate(rendered: rendered) {
                tokenizer.encode(text: $0)
            }

            for slot in rendered.slots {
                _ = try LabelVocabulary.validateSingleTokenLabels(slot.labels) {
                    tokenizer.encode(text: $0)
                }
            }

            // mlx-swift-lm's public generation surface does not expose the complete
            // [sequence, vocabulary] prefill logits required by decider-2b. Calling
            // generate() here would silently change the classifier into text
            // generation. Keep semantic approval fail-closed until a public raw
            // LanguageModel forward path is wired and parity-tested.
            throw MLXDecisionEngineError.forwardPassUnavailable
        }
    }
}
