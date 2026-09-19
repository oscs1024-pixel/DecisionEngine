import DecisionEngineCore
import Foundation
import MCP

actor EnvironmentDecisionEngine: DecisionEngine {
    private var loaded = false

    var isLoaded: Bool { get async { loaded } }

    func loadModel(configuration: ModelRegistration) async throws {
        // This transport executable keeps model loading behind the core protocol.
        // Replace this adapter with MLXDecisionEngine when the checkpoint has been
        // converted to an MLX-supported Qwen3.5 architecture.
        loaded = true
    }

    func unloadModel() async { loaded = false }

    func decide(state: DecisionState, questions: [DecisionQuestion]) async throws -> [DecisionAnswer] {
        throw DecisionEngineError.invalidAnswer(
            "No local inference backend configured. Set up an MLX-compatible decider checkpoint."
        )
    }
}

@main
struct DecisionEngineMCP {
    static func main() async throws {
        let engine = EnvironmentDecisionEngine()
        let router = DecisionRouter(engine: engine)
        let approval = SemanticApprovalGate(engine: engine)
        let reviewer = QualityReviewer(engine: engine)
        let hardGate = HardPolicyGate()

        let server = Server(
            name: "DecisionEngine",
            version: "0.1.0",
            capabilities: .init(tools: .init(listChanged: false))
        )

        await server.withMethodHandler(ListTools.self) { _ in
            .init(tools: [
                Tool(
                    name: "route_turn",
                    description: "Route a coding-agent turn to a configured model tier.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "task": .object(["type": .string("string")]),
                            "context": .object(["type": .string("string")])
                        ]),
                        "required": .array([.string("task")])
                    ])
                ),
                Tool(
                    name: "approve_command",
                    description: "Evaluate a proposed shell command with deterministic and semantic safety gates.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "task": .object(["type": .string("string")]),
                            "command": .object(["type": .string("string")])
                        ]),
                        "required": .array([.string("task"), .string("command")])
                    ])
                ),
                Tool(
                    name: "score_quality",
                    description: "Return structured quality dimensions for a proposed implementation.",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "task": .object(["type": .string("string")]),
                            "context": .object(["type": .string("string")])
                        ]),
                        "required": .array([.string("task"), .string("context")])
                    ])
                )
            ])
        }

        await server.withMethodHandler(CallTool.self) { params in
            let args = params.arguments ?? [:]
            func string(_ key: String) -> String? {
                guard case .string(let value) = args[key] else { return nil }
                return value
            }
            func text(_ value: String, isError: Bool = false) -> CallTool.Result {
                .init(content: [.text(value)], isError: isError)
            }

            do {
                switch params.name {
                case "route_turn":
                    guard let task = string("task") else { return text("Missing task", isError: true) }
                    let decision = try await router.route(
                        state: .init(task: task, context: string("context") ?? "")
                    )
                    let data = try JSONEncoder().encode(decision)
                    return text(String(decoding: data, as: UTF8.self))

                case "approve_command":
                    guard let task = string("task"), let command = string("command") else {
                        return text("Missing task or command", isError: true)
                    }
                    switch hardGate.evaluate(command: command) {
                    case .block(let reason):
                        return text(#"{"decision":"block","reason":"#(reason)"}"#)
                    case .escalate:
                        let decision = await approval.approve(
                            state: .init(task: task, proposedAction: command)
                        )
                        return text(#"{"decision":"#(decision.rawValue)"}"#)
                    }

                case "score_quality":
                    guard let task = string("task"), let context = string("context") else {
                        return text("Missing task or context", isError: true)
                    }
                    let report = try await reviewer.review(state: .init(task: task, context: context))
                    return text(String(describing: report))

                default:
                    return text("Unknown tool: \(params.name)", isError: true)
                }
            } catch {
                return text("Decision engine error: \(error)", isError: true)
            }
        }

        let transport = StdioTransport()
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }
}
