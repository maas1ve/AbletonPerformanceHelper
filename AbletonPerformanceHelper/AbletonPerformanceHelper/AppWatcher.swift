import Foundation
import AppKit

class AppWatcher {
    private var timer: Timer?
    private let onAbletonLaunch: () -> Void
    private var hasLaunchedAbleton = false

    init(onAbletonLaunch: @escaping () -> Void) {
        self.onAbletonLaunch = onAbletonLaunch
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            let running = NSWorkspace.shared.runningApplications
            let isAbletonRunning = running.contains { $0.localizedName?.contains("Ableton Live") == true }
            if isAbletonRunning && !self.hasLaunchedAbleton {
                self.hasLaunchedAbleton = true
                self.onAbletonLaunch()
            } else if !isAbletonRunning {
                self.hasLaunchedAbleton = false
            }
        }
    }
}
