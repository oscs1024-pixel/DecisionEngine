import Foundation

public protocol DecisionEngine: Actor {
    func loadModel(configuration: ModelRegistration) async throws
    func unloadModel() async
    func decide(state: DecisionState, questions: [DecisionQuestion]) async throws -> [DecisionAnswer]
    var isLoaded: Bool { get async }
}

public enum DecisionEngineError: Error, Sendable {
    case missingAnswer(String)
    case invalidAnswer(String)
}
