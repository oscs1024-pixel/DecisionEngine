import Foundation

public struct RenderedDecisionPrompt: Sendable, Equatable {
    public struct Slot: Sendable, Equatable {
        public let question: DecisionQuestion
        public let optionNames: [String]
        public let labels: [String]
        public let marker: String
        public var questionId: String { question.id }
    }
    public let text: String
    public let slots: [Slot]
}

public enum PromptBuilder {
    public static func decider(state: DecisionState, questions: [DecisionQuestion]) throws -> RenderedDecisionPrompt {
        var context = state.task
        if !state.context.isEmpty { context += "\n\n" + state.context }
        if let action = state.proposedAction { context += "\n\nProposed action: " + action }
        var lines = ["Context:", context]
        var slots: [RenderedDecisionPrompt.Slot] = []
        for (index, question) in questions.enumerated() {
            let options: [String]
            switch question.type {
            case .choice(let criteria): options = criteria.keys.sorted()
            case .score(let levels): options = levels
            case .noul: options = ["yes", "no"]
            }
            let labels = try LabelVocabulary.labels(count: options.count)
            let number = index + 1
            lines += ["", "Question \(number): \(question.instructions)", "Options:"]
            for (label, option) in zip(labels, options) { lines.append("(\(label)) \(option)") }
            let marker = "Answer \(number): ("
            lines.append(marker)
            slots.append(.init(question: question, optionNames: options, labels: labels, marker: marker))
        }
        return .init(text: lines.joined(separator: "\n"), slots: slots)
    }
    public static func stateFirst(state: DecisionState, questions: [DecisionQuestion]) -> String {
        (try? decider(state: state, questions: questions).text) ?? ""
    }
}
