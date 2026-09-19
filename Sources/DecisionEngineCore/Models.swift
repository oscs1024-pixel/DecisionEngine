import Foundation

public enum QuestionType: Codable, Sendable, Equatable {
    case choice(criteria: [String: String?])
    case score(levels: [String])
    case noul
}

public struct DecisionQuestion: Codable, Sendable, Equatable {
    public let id: String
    public let type: QuestionType
    public let instructions: String

    public init(id: String, type: QuestionType, instructions: String) {
        self.id = id; self.type = type; self.instructions = instructions
    }
}

public struct DecisionState: Codable, Sendable, Equatable {
    public var task: String
    public var context: String
    public var proposedAction: String?

    public init(task: String, context: String = "", proposedAction: String? = nil) {
        self.task = task; self.context = context; self.proposedAction = proposedAction
    }
}

public struct DecisionAnswer: Codable, Sendable, Equatable {
    public let questionId: String
    public let selectedOption: String?
    public let scoreValue: Double?
    public let noulProbability: Double?
    public let probabilities: [String: Double]
    public let confidence: Double?

    public init(questionId: String, selectedOption: String? = nil, scoreValue: Double? = nil,
                noulProbability: Double? = nil, probabilities: [String: Double] = [:],
                confidence: Double? = nil) {
        self.questionId = questionId; self.selectedOption = selectedOption
        self.scoreValue = scoreValue; self.noulProbability = noulProbability
        self.probabilities = probabilities; self.confidence = confidence
    }
}

import Foundation

public struct ModelRegistration: Codable, Sendable, Equatable {
    public enum Location: Codable, Sendable, Equatable {
        case hub(String)
        case directory(String)
    }

    public let modelId: String
    public let location: Location?

    public init(modelId: String, location: Location? = nil) {
        self.modelId = modelId
        self.location = location
    }
}

public enum ModelTier: String, Codable, Sendable { case mechanical, standard, complex }

public struct RouteDecision: Codable, Sendable, Equatable {
    public let tier: ModelTier
    public let model: String
    public let confidence: Double
    public let reason: String

    public init(tier: ModelTier, model: String, confidence: Double, reason: String) {
        self.tier = tier; self.model = model; self.confidence = confidence; self.reason = reason
    }
}

public enum ApprovalDecision: String, Codable, Sendable { case allow, block, review }
