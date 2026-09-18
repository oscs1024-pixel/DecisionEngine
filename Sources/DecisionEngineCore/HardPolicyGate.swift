import Foundation

public struct HardPolicyGate: Sendable {
    public enum Result: Sendable, Equatable { case block(reason: String), escalate }

    private let blockedFragments = ["rm -rf /", "mkfs", "dd if=", "> /dev/sda"]
    private let protectedFragments = ["/.ssh", "/.aws", "/Library/Keychains"]

    public init() {}

    public func evaluate(command: String) -> Result {
        let normalized = command.lowercased().replacingOccurrences(of: "\\", with: "/")
        if let fragment = blockedFragments.first(where: { normalized.contains($0.lowercased()) }) {
            return .block(reason: "blocked command pattern: \(fragment)")
        }
        if let fragment = protectedFragments.first(where: { normalized.contains($0.lowercased()) }) {
            return .block(reason: "protected credential path: \(fragment)")
        }
        return .escalate
    }
}
