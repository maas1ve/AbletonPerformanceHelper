import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var watcher: AppWatcher!
    private var perfOn = false                 // single source of truth
    private let stateFile = ("~/Library/Application Support/AbletonPerformanceHelper/.perf_on" as NSString).expandingTildeInPath
    private var stateSyncTimer: Timer?
    private var strictMode = false
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("[AppDelegate] setupStatusItem called")
        print("[AppDelegate] applicationDidFinishLaunching")

        NSApp.setActivationPolicy(.regular)
        setupMainMenu()
        setupStatusItem()

        // Ask once for notification permission (modern UNUserNotificationCenter)
        NotificationHelper.requestPermission()

        // Sync initial state from state file (in case LaunchAgent toggled before app started)
        perfOn = FileManager.default.fileExists(atPath: stateFile)
        rebuildStatusMenu()

        // Keep menu state in sync if LaunchAgent changes it while app is running
        stateSyncTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let exists = FileManager.default.fileExists(atPath: self.stateFile)
            if exists != self.perfOn {
                self.perfOn = exists
                self.rebuildStatusMenu()
            }
        }

        startWatcher()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stateSyncTimer?.invalidate()
        stateSyncTimer = nil
    }

    // MARK: - Main (app) menu from .xib equivalent
    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Application"
        let appMenu = NSMenu(title: appName)
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "About \(appName)", action: #selector(showAboutPanel), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Preferences…", action: #selector(openConfig(_:)), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit \(appName)", action: #selector(quitApp), keyEquivalent: "q")

        NSApp.mainMenu = mainMenu
    }

    // MARK: - Status bar menu
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else {
            print("[StatusItem] ❌ No button (unexpected)")
            return
        }

        // Try your asset, then an SF Symbol, then text fallback
        if let img = NSImage(named: "MenuBarIcon") {
            img.isTemplate = true
            button.image = img
            print("[StatusItem] ✅ Using asset MenuBarIcon")
        } else if let sym = NSImage(systemSymbolName: "slider.horizontal.3",
                                    accessibilityDescription: "Ableton Performance Helper") {
            sym.isTemplate = true
            button.image = sym
            print("[StatusItem] ✅ Using SF Symbol slider.horizontal.3")
        } else {
            button.title = "APH" // <-- guarantees visibility
            print("[StatusItem] ✅ Using text fallback")
        }

        rebuildStatusMenu()
    }

    private func rebuildStatusMenu() {
        let menu = NSMenu()

        let toggleTitle = perfOn ? "Disable Performance Mode" : "Enable Performance Mode"
        menu.addItem(withTitle: toggleTitle, action: #selector(togglePerformanceMode), keyEquivalent: "t")

        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Install Login Monitor", action: #selector(installMonitor), keyEquivalent: "")
        menu.addItem(withTitle: "Remove Login Monitor",  action: #selector(removeMonitor), keyEquivalent: "")
        
        menu.addItem(NSMenuItem.separator())
        let strictItem = NSMenuItem(title: "Strict Mode (kill contactsd, AddressBook…)", action: #selector(toggleStrictMode), keyEquivalent: "")
        strictItem.state = strictMode ? .on : .off
        menu.addItem(strictItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "View Log…", action: #selector(openLog), keyEquivalent: "l")

        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Open Config", action: #selector(openConfig(_:)), keyEquivalent: ",")

        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quitApp), keyEquivalent: "q")

        statusItem.menu = menu
    }

    // MARK: - Unified performance mode setter
    private func setPerformanceMode(_ enable: Bool, source: String) {
        if enable {
            let env = strictMode ? ["STRICT": "1"] : [:]
            _ = ScriptRunner.runScript(named: "enable_performance_mode.sh", env: env)
            perfOn = true
            NotificationHelper.sendNotification(title: "Performance Mode Enabled", body: "Triggered by \(source)\(strictMode ? " (Strict)" : "")")
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
    @objc private func togglePerformanceMode() {
        setPerformanceMode(!perfOn, source: "Menu")
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

    @IBAction func openConfig(_ sender: Any) {
        ConfigWindow.show()
    }

    @objc func showAboutPanel() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc private func toggleStrictMode() {
        strictMode.toggle()
        rebuildStatusMenu()
    }

}
