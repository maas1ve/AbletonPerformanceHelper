import Foundation
import AppKit

class AppWatcher {
    private var timer: Timer?
    private let onLaunch: () -> Void
    private var hasLaunched = false

    init(onLaunch: @escaping () -> Void) {
        self.onLaunch = onLaunch
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
                if UserDefaults.standard.bool(forKey: "autoEnable") {
                    self.onLaunch()
                }
            } else if !isRunning {
                self.hasLaunched = false
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
}
