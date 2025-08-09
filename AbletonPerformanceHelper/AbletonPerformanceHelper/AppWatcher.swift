import Foundation
import AppKit

class AppWatcher {
    private var timer: Timer?
    private let onLaunch: () -> Void
    private let onQuit: () -> Void
    private var hasLaunched = false

    init(onLaunch: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onLaunch = onLaunch
        self.onQuit = onQuit
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            let dawName = UserDefaults.standard.string(forKey: "selectedDAW") ?? "Ableton Live"
            let running = NSWorkspace.shared.runningApplications
            let isRunning = running.contains { app in
                guard let name = app.localizedName else { return false }
                if dawName == "Ableton Live" {
                    return name.contains("Ableton Live")
                }
                return name == dawName
            }

            if isRunning && !self.hasLaunched {
                self.hasLaunched = true
                self.onLaunch()
            } else if !isRunning && self.hasLaunched {
                self.hasLaunched = false
                self.onQuit()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
}
