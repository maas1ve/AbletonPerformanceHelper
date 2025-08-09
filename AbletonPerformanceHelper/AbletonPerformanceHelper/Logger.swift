import Foundation

enum LogLevel: String { case info = "INFO", warn = "WARN", error = "ERROR" }

enum AppLogger {
    private static let fm = FileManager.default
    private static var logURL: URL = {
        let base = try! fm.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Logs", isDirectory: true)
        try? fm.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("AbletonPerformanceMode.log")
    }()

    static func write(_ level: LogLevel = .info, _ message: String) {
        let ts = ISO8601DateFormatter().string(from: Date())
        let line = "\(ts) [\(level.rawValue)] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        if fm.fileExists(atPath: logURL.path) {
            if let h = try? FileHandle(forWritingTo: logURL) {
                defer { try? h.close() }
                _ = try? h.seekToEnd()
                try? h.write(contentsOf: data)
            }
        } else {
            try? data.write(to: logURL)
        }
        // Also echo to Xcode console:
        print(line, terminator: "")
    }

    static func logPath() -> String { logURL.path }
}
