import Foundation

public actor DecisionRouter {
    public struct Policy: Sendable {
        public var confidenceThreshold: Double = 0.5
        public var mechanicalUpperBound: Double = 0.3
        public var complexLowerBound: Double = 0.7
        public var mechanicalModel = "gpt-5.6-luna"
        public var standardModel = "gpt-5.6-sol"
        public var complexModel = "gpt-6-astra"
        public init() {}
    }

    private let engine: any DecisionEngine
    private let policy: Policy

    public init(engine: any DecisionEngine, policy: Policy = .init()) {
        self.engine = engine; self.policy = policy
    }

    public func route(state: DecisionState) async throws -> RouteDecision {
        let questions = [
            DecisionQuestion(id: "complexity", type: .score(levels: ["trivial","simple","moderate","complex"]),
                             instructions: "Rate implementation complexity."),
            DecisionQuestion(id: "needs_planning", type: .noul,
                             instructions: "Does this turn require deliberate planning?"),
            DecisionQuestion(id: "safety", type: .choice(criteria: ["safe": nil, "review": nil, "block": nil]),
                             instructions: "Classify the proposed turn's safety.")
        ]
        let answers = try await engine.decide(state: state, questions: questions)
        let byId = Dictionary(uniqueKeysWithValues: answers.map { ($0.questionId, $0) })
        guard let complexity = byId["complexity"], let planning = byId["needs_planning"],
              let safety = byId["safety"] else { throw DecisionEngineError.missingAnswer("routing") }

        let confidence = answers.compactMap(\.confidence).min() ?? 0
        if safety.selectedOption == "block" {
            return .init(tier: .standard, model: policy.standardModel, confidence: confidence, reason: "semantic safety block")
        }
        if confidence < policy.confidenceThreshold || (planning.noulProbability ?? 0) >= 0.5 {
            return .init(tier: .standard, model: policy.standardModel, confidence: confidence, reason: "confidence/planning fallback")
        }

        let raw = complexity.scoreValue ?? 0.5
        let normalized = min(1, max(0, raw))
        if normalized < policy.mechanicalUpperBound {
            return .init(tier: .mechanical, model: policy.mechanicalModel, confidence: confidence, reason: "low complexity")
        }
        if normalized >= policy.complexLowerBound {
            return .init(tier: .complex, model: policy.complexModel, confidence: confidence, reason: "high complexity")
        }
        return .init(tier: .standard, model: policy.standardModel, confidence: confidence, reason: "medium complexity")
    }
}
