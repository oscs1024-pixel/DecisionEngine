import DecisionEngineCore
import Foundation

public enum SlotLocatorError: Error, Equatable {
    case markerNotFound(String)
    case markerNotUnique(String)
    case tokenizationNotPrefixStable(String)
}

public enum SlotLocator {
    public static func locate(rendered: RenderedDecisionPrompt, encode: (String) throws -> [Int]) throws -> [Int] {
        let full = try encode(rendered.text)
        var positions: [Int] = []
        for slot in rendered.slots {
            guard let range = rendered.text.range(of: slot.marker) else { throw SlotLocatorError.markerNotFound(slot.marker) }
            let suffix = rendered.text[range.upperBound...]
            if suffix.range(of: slot.marker) != nil { throw SlotLocatorError.markerNotUnique(slot.marker) }
            let prefix = String(rendered.text[..<range.upperBound])
            let prefixTokens = try encode(prefix)
            guard !prefixTokens.isEmpty, prefixTokens.count <= full.count,
                  Array(full.prefix(prefixTokens.count)) == prefixTokens else {
                throw SlotLocatorError.tokenizationNotPrefixStable(slot.marker)
            }
            positions.append(prefixTokens.count - 1)
        }
        return positions
    }
}
