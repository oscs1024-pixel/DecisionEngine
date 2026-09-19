import Foundation

public actor SemanticApprovalGate {
    private let engine: any DecisionEngine
    public init(engine: any DecisionEngine) { self.engine = engine }

    public func approve(state: DecisionState) async -> ApprovalDecision {
        do {
            let qs = [
                DecisionQuestion(id: "in_scope", type: .noul, instructions: "Is the proposed operation in scope?"),
                DecisionQuestion(id: "destructive", type: .noul, instructions: "Is it destructive or irreversible?")
            ]
            let a = try await engine.decide(state: state, questions: qs)
            let m = Dictionary(uniqueKeysWithValues: a.map { ($0.questionId, $0) })
            guard let scope = m["in_scope"]?.noulProbability,
                  let destructive = m["destructive"]?.noulProbability else { return .block }
            if destructive > 0.7 { return .block }
            if scope > 0.85 && destructive < 0.3 { return .allow }
            return .review
        } catch {
            return .block
        }
    }
}
