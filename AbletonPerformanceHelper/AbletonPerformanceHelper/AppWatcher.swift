import Foundation
import AppKit

final class AppWatcher {
    private var timer: Timer?
    private let onLaunch: () -> Void
    private let onQuit: () -> Void
    private var sawRunning = false

    init(onLaunch: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onLaunch = onLaunch
        self.onQuit   = onQuit
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            let dawName = UserDefaults.standard.string(forKey: "selectedDAW") ?? "Ableton Live"
            let isRunning = NSWorkspace.shared.runningApplications.contains { app in
                guard let name = app.localizedName else { return false }
                return (dawName == "Ableton Live") ? name.contains("Ableton Live") : name == dawName
            }

            if isRunning && !self.sawRunning { self.sawRunning = true;  self.onLaunch() }
            else if !isRunning && self.sawRunning { self.sawRunning = false; self.onQuit() }
        }
    }

    func stopMonitoring() { timer?.invalidate(); timer = nil }
}
