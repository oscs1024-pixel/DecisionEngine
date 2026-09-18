import DecisionEngineCore
import Foundation

/// Lightweight preflight used before downloading/loading a checkpoint.
public enum DeciderPreflight {
    public static func validate(questions: [DecisionQuestion]) throws {
        for question in questions {
            let count: Int
            switch question.type {
            case .choice(let criteria): count = criteria.count
            case .score(let levels): count = levels.count
            case .noul: count = 2
            }
            guard (2...10).contains(count) else {
                throw DecisionEngineError.invalidAnswer("\(question.id): decider-2b requires 2...10 options")
            }
        }
    }
}
