import Foundation

class ScriptRunner {
    static func runScript(named scriptName: String) {
        // Strip ".sh" if it's included by mistake
        let baseName = scriptName.replacingOccurrences(of: ".sh", with: "")
        
        // Locate the script inside the app bundle Resources directory
        guard let scriptPath = Bundle.main.path(forResource: baseName, ofType: "sh") else {
            print("Script not found: \(baseName).sh")
            return
        }

        // Run the script with zsh
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = [scriptPath]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        task.launch()

        // Capture output
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            print("Output from \(baseName):\n\(output)")
        }
    }
}
