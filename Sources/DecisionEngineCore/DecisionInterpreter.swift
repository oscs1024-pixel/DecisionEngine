import Foundation

public enum DecisionInterpreter {
    public static func answer(
        question: DecisionQuestion,
        optionNames: [String],
        logits: [Double],
        temperature: Double = 1.0
    ) throws -> DecisionAnswer {
        guard optionNames.count == logits.count, !optionNames.isEmpty else {
            throw DecisionEngineError.invalidAnswer(question.id)
        }
        guard temperature.isFinite, temperature > 0 else { throw DecisionEngineError.invalidAnswer(question.id) }
        let probabilities = DecisionMath.softmax(logits.map { $0 / temperature })
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
