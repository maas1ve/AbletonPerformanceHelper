//
//  LogLevel.swift
//  AbletonPerformanceHelper
//
//  Created by Lewis Edwards on 09/08/2025.
//


import Foundation

public enum LogLevel: String { case info = "INFO", warn = "WARN", error = "ERROR" }

public enum SharedLog {
    private static let fm = FileManager.default
    private static var url: URL = {
        let base = try! fm.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Logs", isDirectory: true)
        try? fm.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("AbletonPerformanceMode.log")
    }()

    public static func write(_ level: LogLevel = .info, _ message: String) {
        let ts = ISO8601DateFormatter().string(from: Date())
        let line = "\(ts) [\(level.rawValue)] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        if fm.fileExists(atPath: url.path) {
            if let h = try? FileHandle(forWritingTo: url) {
                defer { try? h.close() }
                try? h.seekToEnd()
                try? h.write(contentsOf: data)
            }
        } else {
            try? data.write(to: url)
        }
        #if DEBUG
        print(line, terminator: "")
        #endif
    }
}
