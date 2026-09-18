import Foundation

public enum LabelVocabularyError: Error, Equatable {
    case tooManyOptions(Int)
    case labelNotSingleToken(String)
    case duplicateToken(Int)
}

/// Generates stable spreadsheet-style labels: A...Z, AA...ZZ, ...
public enum LabelVocabulary {
    public static func label(for index: Int) -> String {
        precondition(index >= 0)
        var n = index + 1
        var result = ""
        while n > 0 {
            n -= 1
            result.insert(Character(UnicodeScalar(65 + (n % 26))!), at: result.startIndex)
            n /= 26
        }
        return result
    }

    public static func labels(count: Int) throws -> [String] {
        guard count >= 0, count <= 255 else { throw LabelVocabularyError.tooManyOptions(count) }
        return (0..<count).map(label(for:))
    }

    public static func validateSingleTokenLabels(
        _ labels: [String],
        encode: (String) throws -> [Int]
    ) throws -> [Int] {
        var ids: [Int] = []
        var seen = Set<Int>()
        for label in labels {
            let encoded = try encode(label)
            guard encoded.count == 1 else { throw LabelVocabularyError.labelNotSingleToken(label) }
            guard seen.insert(encoded[0]).inserted else { throw LabelVocabularyError.duplicateToken(encoded[0]) }
            ids.append(encoded[0])
        }
        return ids
    }
}
