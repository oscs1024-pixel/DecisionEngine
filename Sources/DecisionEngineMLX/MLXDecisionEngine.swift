import DecisionEngineCore
import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import MLXLMTokenizers

/// Qwen3.5-capable MLX backend.
///
/// The current mlx-swift-lm registry supports qwen3_5 / qwen3_5_text.
/// This type owns loading and lifecycle. Slot-logit extraction remains isolated
/// in `DeciderForwardPass` so it can be parity-tested against the checkpoint.
public actor MLXDecisionEngine: DecisionEngine {
    private var registration: ModelRegistration?
    private var loaded = false

    public init() {}

    public var isLoaded: Bool { get async { loaded } }

    public func loadModel(configuration: ModelRegistration) async throws {
        // Keep the public lifecycle stable while the exact converted decider
        // artifact is selected. mlx-swift-lm now supports Qwen3.5; the next
        // checkpoint-specific step is loading via LLMModelFactory and validating
        // tokenizer label IDs before marking this backend ready.
        registration = configuration
        loaded = true
    }

    public func unloadModel() async {
        registration = nil
        loaded = false
    }

    public func decide(
        state: DecisionState,
        questions: [DecisionQuestion]
    ) async throws -> [DecisionAnswer] {
        guard loaded, registration != nil else {
            throw DecisionEngineError.invalidAnswer("MLX model is not loaded")
        }
        throw DecisionEngineError.invalidAnswer(
            "Checkpoint loaded lifecycle is configured; decider slot-logit forward pass requires a converted Mapika/decider-2b artifact and parity fixture."
        )
    }
}
