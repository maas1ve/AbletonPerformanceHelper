import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var watcher: AppWatcher!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🎛"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Enable Performance Mode", action: #selector(enablePerformanceMode), keyEquivalent: "E"))
        menu.addItem(NSMenuItem(title: "Restore Normal Mode", action: #selector(restoreNormalMode), keyEquivalent: "R"))
        menu.addItem(NSMenuItem(title: "Open Config", action: #selector(openConfig), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
        watcher = AppWatcher(onAbletonLaunch: {
            ScriptRunner.runScript(named: "enable_performance_mode.sh")
            NotificationHelper.sendNotification(title: "Ableton Detected", body: "Performance Mode Enabled")
        })
        watcher.startMonitoring()
    }

    @objc func enablePerformanceMode() {
        ScriptRunner.runScript(named: "enable_performance_mode.sh")
    }

    @objc func restoreNormalMode() {
        ScriptRunner.runScript(named: "restore_normal_mode.sh")
    }

    @objc func openConfig() {
        ConfigWindow.show()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
