import AppKit
import Foundation

final class LaunchAgentManager {
    static let shared = LaunchAgentManager()

    private let fm = FileManager.default
    private let label = "com.kohai.AbletonPerfHelper.monitor"
    private var agentsDir: URL { URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/LaunchAgents", isDirectory: true) }
    private var appSupportDir: URL {
        let url = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/AbletonPerformanceHelper", isDirectory: true)
        try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    private var plistURL: URL { agentsDir.appendingPathComponent("\(label).plist") }

    func installOrUpdateMonitor() throws {
        try fm.createDirectory(at: agentsDir, withIntermediateDirectories: true)
        let plist = makePlist(programPath: appSupportDir.appendingPathComponent("monitor_ableton.sh").path,
                              logPath: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Logs/AbletonPerformanceMode.log").path)
        try plist.write(to: plistURL, atomically: true, encoding: .utf8)
        try copyBundledScript("monitor_ableton")
        try bootoutIfLoaded()
        try bootstrap()
        AppLogger.write(.info, "LaunchAgent installed and started: \(label)")
    }

    func removeMonitor() throws {
        try bootoutIfLoaded()
        try? fm.removeItem(at: plistURL)
        AppLogger.write(.info, "LaunchAgent removed: \(label)")
    }

    func isInstalled() -> Bool { fm.fileExists(atPath: plistURL.path) }

    private func copyBundledScript(_ name: String) throws {
        guard let src = Bundle.main.url(forResource: name, withExtension: "sh", subdirectory: "Scripts") else {
            throw NSError(domain: "LaunchAgent", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bundled script \(name).sh not found"])
        }
        let dst = appSupportDir.appendingPathComponent("\(name).sh")
        if fm.fileExists(atPath: dst.path) { try? fm.removeItem(at: dst) }
        try fm.copyItem(at: src, to: dst)
        _ = try? Process.run(URL(fileURLWithPath: "/bin/chmod"), arguments: ["+x", dst.path])
    }

    private func makePlist(programPath: String, logPath: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key><string>\(label)</string>
          <key>ProgramArguments</key>
          <array>
            <string>\(programPath)</string>
          </array>
          <key>RunAtLoad</key><true/>
          <key>KeepAlive</key><true/>
          <key>StandardOutPath</key><string>\(logPath)</string>
          <key>StandardErrorPath</key><string>\(logPath)</string>
        </dict>
        </plist>
        """
    }

    @discardableResult
    private func run(_ tool: String, _ args: [String]) throws -> (Int32, String) {
        let p = Process(); p.executableURL = URL(fileURLWithPath: tool); p.arguments = args
        let out = Pipe(); p.standardOutput = out; p.standardError = out
        try p.run(); p.waitUntilExit()
        let txt = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        if p.terminationStatus != 0 { throw NSError(domain: "LaunchAgent", code: Int(p.terminationStatus), userInfo: [NSLocalizedDescriptionKey: txt]) }
        return (p.terminationStatus, txt)
    }

    private func bootstrap() throws {
        try run("/bin/launchctl", ["bootstrap", "gui/\(getuid())", plistURL.path])
        try run("/bin/launchctl", ["enable", "gui/\(getuid())/\(label)"])
    }
    private func bootoutIfLoaded() throws {
        _ = try? run("/bin/launchctl", ["bootout", "gui/\(getuid())/\(label)"])
    }
}
