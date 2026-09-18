import Foundation

public struct DeciderParityFixture: Codable, Sendable, Equatable {
    public struct Question: Codable, Sendable, Equatable {
        public let id: String
        public let answerSlotTokenIndex: Int
        public let labels: [String]
        public let labelTokenIds: [Int]
        public let referenceProbabilities: [Double]
    }
    public let model: String
    public let prompt: String
    public let tokenIds: [Int]
    public let questions: [Question]
    public let temperature: Double
}

public enum ParityValidator {
    public static func validate(actual: [Double], reference: [Double], tolerance: Double = 1e-4) -> Bool {
        guard actual.count == reference.count else { return false }
        return zip(actual, reference).allSatisfy { abs($0 - $1) <= tolerance }
    }
}
