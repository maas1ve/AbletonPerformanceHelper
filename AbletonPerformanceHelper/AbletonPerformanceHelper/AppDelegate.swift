import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var watcher: AppWatcher!

    private var perfOn = false
    private var strictMode  = UserDefaults.standard.bool(forKey: "strictMode")
    private var extremeMode = UserDefaults.standard.bool(forKey: "extremeMode")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("[AppDelegate] applicationDidFinishLaunching")

        setupMainMenu()
        setupStatusItem()
        NotificationHelper.requestPermission()

        // Initial performance mode state from .perf_on file
        let stateFile = ("~/Library/Application Support/AbletonPerformanceHelper/.perf_on" as NSString).expandingTildeInPath
        perfOn = FileManager.default.fileExists(atPath: stateFile)
        rebuildStatusMenu()

        // Watch for external state changes (e.g. LaunchAgent)
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            let on = FileManager.default.fileExists(atPath: stateFile)
            if on != self.perfOn {
                self.perfOn = on
                self.rebuildStatusMenu()
            }
        }

        startWatcher()
    }

    // MARK: - Top app menu
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
        } else if let sym = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: "Ableton Performance Helper") {
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

        // Tier 1 — Basic toggles
        let toggleTitle = perfOn ? "Disable Performance Mode" : "Enable Performance Mode"
        menu.addItem(withTitle: toggleTitle, action: #selector(togglePerformanceMode), keyEquivalent: "t")

        menu.addItem(NSMenuItem.separator())
        let strictItem = NSMenuItem(title: "Strict Mode (kill Contacts agents)", action: #selector(toggleStrictMode), keyEquivalent: "")
        strictItem.state = strictMode ? .on : .off
        menu.addItem(strictItem)

        let extremeItem = NSMenuItem(title: "Extreme Mode (telemetry & analysis off)", action: #selector(toggleExtremeMode), keyEquivalent: "")
        extremeItem.state = extremeMode ? .on : .off
        menu.addItem(extremeItem)

        // Tier 2 — Advanced (Admin) tweaks
        let adminMenu = NSMenu()
        adminMenu.addItem(NSMenuItem(title: "Spotlight: Disable", action: #selector(disableSpotlight), keyEquivalent: ""))
        adminMenu.addItem(NSMenuItem(title: "Spotlight: Enable", action: #selector(enableSpotlight), keyEquivalent: ""))
        adminMenu.addItem(NSMenuItem.separator())
        adminMenu.addItem(NSMenuItem(title: "Power Preset: Audio", action: #selector(setAudioPreset), keyEquivalent: ""))
        adminMenu.addItem(NSMenuItem(title: "Power Preset: Default", action: #selector(setDefaultPreset), keyEquivalent: ""))
        adminMenu.addItem(NSMenuItem.separator())
        adminMenu.addItem(NSMenuItem(title: "Disable Apple Intelligence", action: #selector(disableAppleIntelligence), keyEquivalent: ""))
        adminMenu.addItem(NSMenuItem(title: "Disable Privacy Intelligence", action: #selector(disablePrivacyIntelligence), keyEquivalent: ""))
        adminMenu.addItem(NSMenuItem(title: "Disable WeatherKit", action: #selector(disableWeatherKit), keyEquivalent: ""))
        adminMenu.addItem(NSMenuItem(title: "Disable Screen Time", action: #selector(disableScreenTime), keyEquivalent: ""))

        let adminItem = NSMenuItem()
        adminItem.title = "Advanced (Admin)"
        menu.setSubmenu(adminMenu, for: adminItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(adminItem)

        // Other items
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Install Login Monitor", action: #selector(installMonitor), keyEquivalent: "")
        menu.addItem(withTitle: "Remove Login Monitor", action: #selector(removeMonitor), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "View Log…", action: #selector(openLog), keyEquivalent: "l")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Open Config", action: #selector(openConfig(_:)), keyEquivalent: ",")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quitApp), keyEquivalent: "q")

        statusItem.menu = menu
    }

    // MARK: - Performance mode setter
    private func setPerformanceMode(_ enable: Bool, source: String) {
        if enable {
            var env: [String: String] = [:]
            if strictMode { env["STRICT"] = "1" }
            if extremeMode { env["EXTREME"] = "1" }
            _ = ScriptRunner.runScript(named: "enable_performance_mode.sh", env: env)
            perfOn = true
            NotificationHelper.sendNotification(
                title: "Performance Mode Enabled",
                body: "Triggered by \(source)\(strictMode ? " (Strict)" : "")\(extremeMode ? " (Extreme)" : "")"
            )
        } else {
            _ = ScriptRunner.runScript(named: "restore_normal_mode.sh")
            perfOn = false
            NotificationHelper.sendNotification(
                title: "Performance Mode Disabled",
                body: "Triggered by \(source)"
            )
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

    // MARK: - Tier 1 Actions
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

    // MARK: - Tier 2 Admin Actions
    @objc private func disableSpotlight() {
        AdminHelperClient.shared.spotlight(enable: false)
    }
    @objc private func enableSpotlight() {
        AdminHelperClient.shared.spotlight(enable: true)
    }
    @objc private func setAudioPreset() {
        AdminHelperClient.shared.applyPMSetPreset("audio")
    }
    @objc private func setDefaultPreset() {
        AdminHelperClient.shared.applyPMSetPreset("default")
    }
    @objc private func disableAppleIntelligence() {
        AdminHelperClient.shared.setSystemDaemon("com.apple.intelligenced", enabled: false)
        AdminHelperClient.shared.setSystemDaemon("com.apple.aiml.appleintelligenceserviced", enabled: false)
    }
    @objc private func disablePrivacyIntelligence() {
        AdminHelperClient.shared.setSystemDaemon("com.apple.PrivacyIntelligence", enabled: false)
    }
    @objc private func disableWeatherKit() {
        AdminHelperClient.shared.setSystemDaemon("com.apple.WeatherKit.service", enabled: false)
    }
    @objc private func disableScreenTime() {
        AdminHelperClient.shared.setSystemDaemon("com.apple.ScreenTimeAgent", enabled: false)
    }

    // MARK: - Misc actions
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
