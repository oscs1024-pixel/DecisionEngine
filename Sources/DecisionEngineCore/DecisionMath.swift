import Foundation

/// Backend-independent probability math used by MLX and parity fixtures.
public enum DecisionMath {
    public static func softmax(_ logits: [Double]) -> [Double] {
        guard let maximum = logits.max(), !logits.isEmpty else { return [] }
        let exps = logits.map { Foundation.exp($0 - maximum) }
        let total = exps.reduce(0, +)
        guard total.isFinite, total > 0 else {
            return Array(repeating: 1 / Double(logits.count), count: logits.count)
        }
        return exps.map { $0 / total }
    }

    public static func normalizedExpectedScore(probabilities: [Double]) -> Double? {
        guard !probabilities.isEmpty else { return nil }
        if probabilities.count == 1 { return 0 }
        let denominator = Double(probabilities.count - 1)
        return probabilities.enumerated().reduce(0) { partial, pair in
            partial + (Double(pair.offset) / denominator) * pair.element
        }
    }

    public static func confidence(_ probabilities: [Double]) -> Double? {
        probabilities.max()
    }
}
