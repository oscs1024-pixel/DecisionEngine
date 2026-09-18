import Foundation

public enum PromptBuilder {
    public static func stateFirst(state: DecisionState, questions: [DecisionQuestion]) -> String {
        var lines = ["State:", state.task]
        if !state.context.isEmpty { lines += ["Context:", state.context] }
        if let action = state.proposedAction { lines += ["Proposed action:", action] }
        for (index, question) in questions.enumerated() {
            lines += ["", "Question \(index + 1) [\(question.id)]:", question.instructions]
            switch question.type {
            case .choice(let criteria):
                lines.append("Options: " + criteria.keys.sorted().joined(separator: ", "))
            case .score(let levels):
                lines.append("Levels: " + levels.joined(separator: ", "))
            case .noul:
                lines.append("Options: yes, no")
            }
            lines.append("Answer: <slot:\(question.id)>")
        }
        return lines.joined(separator: "\n")
    }
}
