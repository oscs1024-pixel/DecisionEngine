import Foundation

public actor RouteLogger {
    private let url: URL
    public init(url: URL? = nil) {
        self.url = url ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".decision-engine/route-log.jsonl")
    }

    public func append(_ decision: RouteDecision) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        var data = try JSONEncoder().encode(decision); data.append(0x0A)
        if fm.fileExists(atPath: url.path) {
            let handle = try FileHandle(forWritingTo: url)
            try handle.seekToEnd(); try handle.write(contentsOf: data); try handle.close()
        } else {
            try data.write(to: url, options: .atomic)
        }
    }
}
