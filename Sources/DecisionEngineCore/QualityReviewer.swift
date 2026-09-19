import Foundation

public struct QualityReport: Sendable, Equatable {
    public let correctness: String?
    public let complexity: String?
    public let hasTestsProbability: Double?
    public let secureProbability: Double?
}

public actor QualityReviewer {
    private let engine: any DecisionEngine
    public init(engine: any DecisionEngine) { self.engine = engine }

    public func review(state: DecisionState) async throws -> QualityReport {
        let qs = [
            DecisionQuestion(id: "correctness", type: .choice(criteria: ["broken":nil,"partial":nil,"correct":nil,"excellent":nil]), instructions: "Assess correctness."),
            DecisionQuestion(id: "complexity", type: .choice(criteria: ["trivial":nil,"simple":nil,"moderate":nil,"overly_complex":nil]), instructions: "Assess implementation complexity."),
            DecisionQuestion(id: "tests", type: .noul, instructions: "Is test coverage adequate?"),
            DecisionQuestion(id: "security", type: .noul, instructions: "Is the implementation secure for its intended scope?")
        ]
        let a = try await engine.decide(state: state, questions: qs)
        let m = Dictionary(uniqueKeysWithValues: a.map { ($0.questionId, $0) })
        return .init(correctness: m["correctness"]?.selectedOption,
                     complexity: m["complexity"]?.selectedOption,
                     hasTestsProbability: m["tests"]?.noulProbability,
                     secureProbability: m["security"]?.noulProbability)
    }
}
