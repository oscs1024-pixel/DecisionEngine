import Foundation

public enum DecisionInterpreter {
    public static func answer(
        question: DecisionQuestion,
        optionNames: [String],
        logits: [Double]
    ) throws -> DecisionAnswer {
        guard optionNames.count == logits.count, !optionNames.isEmpty else {
            throw DecisionEngineError.invalidAnswer(question.id)
        }
        let probabilities = DecisionMath.softmax(logits)
        let distribution = Dictionary(uniqueKeysWithValues: zip(optionNames, probabilities))
        let best = probabilities.enumerated().max(by: { $0.element < $1.element })?.offset
        let confidence = DecisionMath.confidence(probabilities)

        switch question.type {
        case .choice:
            return .init(questionId: question.id,
                         selectedOption: best.map { optionNames[$0] },
                         probabilities: distribution,
                         confidence: confidence)
        case .score:
            return .init(questionId: question.id,
                         scoreValue: DecisionMath.normalizedExpectedScore(probabilities: probabilities),
                         probabilities: distribution,
                         confidence: confidence)
        case .noul:
            guard optionNames == ["yes", "no"] else { throw DecisionEngineError.invalidAnswer(question.id) }
            return .init(questionId: question.id,
                         noulProbability: probabilities[0],
                         probabilities: distribution,
                         confidence: confidence)
        }
    }
}
