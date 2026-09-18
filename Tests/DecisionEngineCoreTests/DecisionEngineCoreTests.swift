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


@Test func softmaxIsStableAndNormalized() {
    let p = DecisionMath.softmax([1000, 1001, 1002])
    #expect(abs(p.reduce(0,+) - 1) < 0.000001)
    #expect(p[2] > p[1] && p[1] > p[0])
}

@Test func scoreIsNormalizedToUnitInterval() throws {
    let q = DecisionQuestion(id:"score", type:.score(levels:["low","mid","high"]), instructions:"score")
    let a = try DecisionInterpreter.answer(question:q, optionNames:["low","mid","high"], logits:[0,0,10])
    #expect((a.scoreValue ?? 0) > 0.99)
}

@Test func noulMapsYesProbability() throws {
    let q = DecisionQuestion(id:"n", type:.noul, instructions:"yes?")
    let a = try DecisionInterpreter.answer(question:q, optionNames:["yes","no"], logits:[5,0])
    #expect((a.noulProbability ?? 0) > 0.99)
}

@Test func labelsExtendPastZ() throws {
    #expect(LabelVocabulary.label(for:0) == "A")
    #expect(LabelVocabulary.label(for:25) == "Z")
    #expect(LabelVocabulary.label(for:26) == "AA")
    #expect(try LabelVocabulary.labels(count:255).count == 255)
}


@Test func deciderPromptUsesLetteredAnswerSlots() throws {
    let rendered = try PromptBuilder.decider(
        state: .init(task:"Fix the failing test"),
        questions:[
            .init(id:"route", type:.choice(criteria:["mechanical":nil,"standard":nil]), instructions:"Choose a tier"),
            .init(id:"safe", type:.noul, instructions:"Is this safe?")
        ]
    )
    #expect(rendered.text.contains("(A) mechanical"))
    #expect(rendered.text.contains("Answer 1: ("))
    #expect(rendered.text.contains("Answer 2: ("))
    #expect(rendered.slots[1].optionNames == ["yes","no"])
}

@Test func interpreterAppliesCalibrationTemperature() throws {
    let q = DecisionQuestion(id:"n", type:.noul, instructions:"yes?")
    let cold = try DecisionInterpreter.answer(question:q, optionNames:["yes","no"], logits:[2,0], temperature:1)
    let warm = try DecisionInterpreter.answer(question:q, optionNames:["yes","no"], logits:[2,0], temperature:2)
    #expect((cold.noulProbability ?? 0) > (warm.noulProbability ?? 0))
}
