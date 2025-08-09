import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    // Status item + state
    var statusItem: NSStatusItem!
    var watcher: AppWatcher!

    // Single source of truth for perf mode (mirrors state file written by helper/monitor)
    private var perfOn = false
    // Toggles
    private var strictMode  = UserDefaults.standard.bool(forKey: "strictMode")   // kills contactsd (best‑effort)
    private var extremeMode = UserDefaults.standard.bool(forKey: "extremeMode")  // kills telemetry/etc. (user-scope)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("[AppDelegate] applicationDidFinishLaunching")

        setupMainMenu()
        setupStatusItem()

        // Sync initial state from the state file if LaunchAgent toggled it before app start
        let stateFile = ("~/Library/Application Support/AbletonPerformanceHelper/.perf_on" as NSString).expandingTildeInPath
        perfOn = FileManager.default.fileExists(atPath: stateFile)
        rebuildStatusMenu()

        // Watch for external changes (LaunchAgent) and reflect in menu
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            let on = FileManager.default.fileExists(atPath: stateFile)
            if on != self.perfOn {
                self.perfOn = on
                self.rebuildStatusMenu()
            }
        }

        startWatcher()
    }

    // MARK: - App menu (programmatic equivalent of a basic .xib menu)
    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)

        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Application"
        let appMenu = NSMenu(title: appName)
        appItem.submenu = appMenu
        appMenu.addItem(withTitle: "About \(appName)", action: #selector(showAboutPanel), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Preferences…", action: #selector(openConfig(_:)), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit \(appName)", action: #selector(quitApp), keyEquivalent: "q")

        NSApp.mainMenu = mainMenu
    }

    // MARK: - Status bar item
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }

        if let img = NSImage(named: "MenuBarIcon") {
            img.isTemplate = true
            button.image = img
            print("[StatusItem] Using asset MenuBarIcon")
        } else if let sym = NSImage(systemSymbolName: "slider.horizontal.3",
                                    accessibilityDescription: "Ableton Performance Helper") {
            sym.isTemplate = true
            button.image = sym
            print("[StatusItem] Using SF Symbol slider.horizontal.3")
        } else {
            button.title = "APH"
            print("[StatusItem] Using text fallback")
        }
        rebuildStatusMenu()
    }

    private func rebuildStatusMenu() {
        let menu = NSMenu()

        // Toggle Performance Mode
        let toggleTitle = perfOn ? "Disable Performance Mode" : "Enable Performance Mode"
        menu.addItem(withTitle: toggleTitle, action: #selector(togglePerformanceMode), keyEquivalent: "t")

        // Strict / Extreme toggles
        menu.addItem(NSMenuItem.separator())
        let strictItem = NSMenuItem(title: "Strict Mode (kill Contacts agents)", action: #selector(toggleStrictMode), keyEquivalent: "")
        strictItem.state = strictMode ? .on : .off
        menu.addItem(strictItem)

        let extremeItem = NSMenuItem(title: "Extreme Mode (telemetry & analysis off)", action: #selector(toggleExtremeMode), keyEquivalent: "")
        extremeItem.state = extremeMode ? .on : .off
        menu.addItem(extremeItem)

        // LaunchAgent helper (monitor) controls
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Install Login Monitor", action: #selector(installMonitor), keyEquivalent: "")
        menu.addItem(withTitle: "Remove Login Monitor",  action: #selector(removeMonitor),  keyEquivalent: "")

        // Log + Preferences + Quit
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "View Log…", action: #selector(openLog), keyEquivalent: "l")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Open Config", action: #selector(openConfig(_:)), keyEquivalent: ",")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quitApp), keyEquivalent: "q")

        statusItem.menu = menu
    }

    // MARK: - Unified setter
    private func setPerformanceMode(_ enable: Bool, source: String) {
        if enable {
            var env: [String:String] = [:]
            if strictMode  { env["STRICT"]  = "1" }
            if extremeMode { env["EXTREME"] = "1" }
            _ = ScriptRunner.runScript(named: "enable_performance_mode.sh", env: env)
            perfOn = true
            NotificationHelper.sendNotification(title: "Performance Mode Enabled", body: "Triggered by \(source)\(strictMode ? " (Strict)" : "")\(extremeMode ? " (Extreme)" : "")")
        } else {
            _ = ScriptRunner.runScript(named: "restore_normal_mode.sh")
            perfOn = false
            NotificationHelper.sendNotification(title: "Performance Mode Disabled", body: "Triggered by \(source)")
        }
        rebuildStatusMenu()
    }

    // MARK: - AppWatcher
    private func startWatcher() {
        watcher = AppWatcher(
            onLaunch: {
                if UserDefaults.standard.bool(forKey: "autoEnable") {
                    self.setPerformanceMode(true, source: "AppWatcher")
                }
            },
            onQuit: {
                if UserDefaults.standard.bool(forKey: "autoEnable") {
                    self.setPerformanceMode(false, source: "AppWatcher")
                }
            }
        )
        watcher.startMonitoring()
    }

    // MARK: - Actions
    @objc private func togglePerformanceMode() { setPerformanceMode(!perfOn, source: "Menu") }

    @objc private func toggleStrictMode() {
        strictMode.toggle()
        UserDefaults.standard.set(strictMode, forKey: "strictMode")
        rebuildStatusMenu()
    }

    @objc private func toggleExtremeMode() {
        extremeMode.toggle()
        UserDefaults.standard.set(extremeMode, forKey: "extremeMode")
        rebuildStatusMenu()
    }

    @objc private func installMonitor() {
        do {
            try LaunchAgentManager.shared.installOrUpdateMonitor()
            NotificationHelper.sendNotification(title: "Login Monitor", body: "Installed and started.")
        } catch {
            NotificationHelper.sendNotification(title: "Install failed", body: error.localizedDescription)
        }
    }

    @objc private func removeMonitor() {
        do {
            try LaunchAgentManager.shared.removeMonitor()
            NotificationHelper.sendNotification(title: "Login Monitor", body: "Removed.")
        } catch {
            NotificationHelper.sendNotification(title: "Remove failed", body: error.localizedDescription)
        }
    }

    @objc private func openLog() {
        let logPath = ("~/Library/Logs/AbletonPerformanceMode.log" as NSString).expandingTildeInPath
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: logPath)])
    }

    @IBAction func openConfig(_ sender: Any) { ConfigWindow.show() }

    @objc private func showAboutPanel() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() { NSApplication.shared.terminate(nil) }
}
