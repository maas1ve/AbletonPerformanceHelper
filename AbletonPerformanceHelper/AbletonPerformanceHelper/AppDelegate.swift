import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var watcher: AppWatcher!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupMainMenu()
        setupStatusItem()
        startWatcher()
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        
        let appMenu = NSMenu(title: "AbletonPerformanceHelper")
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "About AbletonPerformanceHelper", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Preferences…", action: #selector(openConfig), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit AbletonPerformanceHelper", action: #selector(quitApp), keyEquivalent: "q")
        
        NSApp.mainMenu = mainMenu
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "speedometer", accessibilityDescription: "Performance")
            button.image?.isTemplate = true
        }
        
        let menu = NSMenu()
        menu.addItem(withTitle: "Enable Performance Mode", action: #selector(enablePerformanceMode), keyEquivalent: "e")
        menu.addItem(withTitle: "Restore Normal Mode", action: #selector(restoreNormalMode), keyEquivalent: "r")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Preferences…", action: #selector(openConfig), keyEquivalent: ",")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quitApp), keyEquivalent: "q")

        statusItem.menu = menu
    }

    private func startWatcher() {
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
