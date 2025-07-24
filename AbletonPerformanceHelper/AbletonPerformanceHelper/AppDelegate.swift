import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var watcher: AppWatcher!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.regular)
        setupMainMenu()
        setupStatusItem()
        startWatcher()
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Application"
        let appMenu = NSMenu(title: appName)
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "About \(appName)", action: #selector(showAboutPanel), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Preferences…", action: #selector(openConfig), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit \(appName)", action: #selector(quitApp), keyEquivalent: "q")

        NSApp.mainMenu = mainMenu
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            // Use the custom asset for the menu bar icon
            button.image = NSImage(named: "MenuBarIcon")
            button.image?.isTemplate = true
        }
        
        let menu = NSMenu()
        menu.addItem(withTitle: "Enable Performance Mode", action: #selector(enablePerformanceMode), keyEquivalent: "e")
        menu.addItem(withTitle: "Open Config", action: #selector(openConfig), keyEquivalent: ",")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quitApp), keyEquivalent: "q")

        statusItem.menu = menu
    }

    private func startWatcher() {
        watcher = AppWatcher(onLaunch: {
            let daw = UserDefaults.standard.string(forKey: "selectedDAW") ?? "Ableton Live"
            ScriptRunner.runScript(named: "enable_performance_mode.sh")
            NotificationHelper.sendNotification(title: "\(daw) Detected", body: "Performance Mode Enabled")
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

    @objc func showAboutPanel() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
