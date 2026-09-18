import Testing
@testable import DecisionEngineCore

actor MockEngine: DecisionEngine {
    var answers: [DecisionAnswer]
    var loaded = true
    init(_ answers: [DecisionAnswer]) { self.answers = answers }
    var isLoaded: Bool { get async { loaded } }
    func loadModel(configuration: ModelRegistration) async throws { loaded = true }
    func unloadModel() async { loaded = false }
    func decide(state: DecisionState, questions: [DecisionQuestion]) async throws -> [DecisionAnswer] { answers }
}

@Test func hardPolicyBlocksDestructiveRootDelete() {
    let gate = HardPolicyGate()
    #expect(gate.evaluate(command: "sudo rm -rf /") != .escalate)
}

@Test func hardPolicyEscalatesOrdinaryCommand() {
    #expect(HardPolicyGate().evaluate(command: "swift test") == .escalate)
}

@Test func lowConfidenceFallsBackToStandard() async throws {
    let engine = MockEngine([
        .init(questionId:"complexity", scoreValue:0.1, confidence:0.4),
        .init(questionId:"needs_planning", noulProbability:0.1, confidence:0.9),
        .init(questionId:"safety", selectedOption:"safe", confidence:0.9)
    ])
    let result = try await DecisionRouter(engine: engine).route(state: .init(task:"rename a local variable"))
    #expect(result.tier == .standard)
}

@Test func confidentSimpleTurnRoutesMechanical() async throws {
    let engine = MockEngine([
        .init(questionId:"complexity", scoreValue:0.1, confidence:0.9),
        .init(questionId:"needs_planning", noulProbability:0.1, confidence:0.9),
        .init(questionId:"safety", selectedOption:"safe", confidence:0.9)
    ])
    let result = try await DecisionRouter(engine: engine).route(state: .init(task:"rename a local variable"))
    #expect(result.tier == .mechanical)
}

@Test func semanticGateFailsClosedOnEngineErrorShape() async {
    let engine = MockEngine([])
    let result = await SemanticApprovalGate(engine: engine).approve(state: .init(task:"run command", proposedAction:"echo ok"))
    #expect(result == .block)
}
