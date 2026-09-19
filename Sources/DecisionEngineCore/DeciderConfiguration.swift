import Foundation

public struct DeciderConfiguration: Codable, Sendable, Equatable {
    public var temperature: Double
    public var maximumContextTokens: Int
    public init(temperature: Double = 1.05, maximumContextTokens: Int = 1536) {
        self.temperature = temperature
        self.maximumContextTokens = maximumContextTokens
    }
}
