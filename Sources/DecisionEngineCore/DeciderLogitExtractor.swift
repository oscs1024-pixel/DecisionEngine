import Foundation

public enum DeciderLogitExtractor {
    public static func extract(
        rendered: RenderedDecisionPrompt,
        slotPositions: [Int],
        labelTokenIds: [[Int]],
        logitsAt: (_ sequencePosition: Int, _ vocabularyToken: Int) throws -> Double,
        temperature: Double
    ) throws -> [DecisionAnswer] {
        guard rendered.slots.count == slotPositions.count,
              rendered.slots.count == labelTokenIds.count else {
            throw DecisionEngineError.invalidAnswer("slot metadata mismatch")
        }
        return try rendered.slots.enumerated().map { index, slot in
            let ids = labelTokenIds[index]
            guard ids.count == slot.optionNames.count else {
                throw DecisionEngineError.invalidAnswer(slot.questionId)
            }
            let values = try ids.map { try logitsAt(slotPositions[index], $0) }
            return try DecisionInterpreter.answer(
                question: slot.question,
                optionNames: slot.optionNames,
                logits: values,
                temperature: temperature
            )
        }
    }
}
