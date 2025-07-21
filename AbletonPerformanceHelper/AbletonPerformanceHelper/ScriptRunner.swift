import Foundation

class ScriptRunner {
    static func runScript(named scriptName: String) {
        let scriptPath = "\(NSHomeDirectory())/github/Ableton-Performance-Mode/Scripts/\(scriptName)"
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", scriptPath]
        task.launch()
    }
}
