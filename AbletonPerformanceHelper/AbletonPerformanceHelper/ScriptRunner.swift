import Foundation

class ScriptRunner {
    @discardableResult
    static func runScript(
        named: String,
        env: [String: String]? = nil,
        args: [String] = []
    ) -> Int32 {

        let scriptURL: URL? = {
            if named.hasPrefix("/") { return URL(fileURLWithPath: named) }
            let base = (named as NSString).deletingPathExtension
            let ext  = (named as NSString).pathExtension.isEmpty ? "sh" : (named as NSString).pathExtension
            return Bundle.main.url(forResource: base, withExtension: ext, subdirectory: "Scripts")
        }()

        guard let url = scriptURL else { print("[ScriptRunner] Not found: \(named)"); return -1 }

        let task = Process()
        task.executableURL = url
        task.arguments = args

        if let env = env {
            var merged = ProcessInfo.processInfo.environment
            env.forEach { merged[$0.key] = $0.value }
            task.environment = merged
        }

        let outPipe = Pipe()
        let errPipe = Pipe()
        task.standardOutput = outPipe
        task.standardError  = errPipe

        do { try task.run() } catch { print("[ScriptRunner] Launch failed: \(error)"); return -2 }
        task.waitUntilExit()

        let stdoutText = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderrText = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        if !stdoutText.isEmpty { print(stdoutText) }
        if !stderrText.isEmpty { FileHandle.standardError.write(Data(stderrText.utf8)) }

        return task.terminationStatus
    }
}
