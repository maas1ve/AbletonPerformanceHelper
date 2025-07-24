import Foundation

class ScriptRunner {
    static func runScript(named scriptName: String) {
        // Locate the script inside the application's bundled resources
        guard let resourcePath = Bundle.main.resourcePath else {
            print("Unable to locate script resources")
            return
        }
        let scriptPath = "\(resourcePath)/Scripts/\(scriptName)"
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", scriptPath]
        task.launch()
    }
}
