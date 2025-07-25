import SwiftUI

struct ConfigWindow: View {
    @AppStorage("selectedDAW") private var selectedDAW: String = DAW.abletonLive.rawValue
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("autoEnable") private var autoEnable: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Digital Audio Workstation", selection: $selectedDAW) {
                ForEach(DAW.allCases) { daw in
                    Text(daw.rawValue).tag(daw.rawValue)
                }
            }
            .pickerStyle(DefaultPickerStyle())

            Toggle("Launch app at login", isOn: $launchAtLogin)
            Toggle("Automatically enable performance mode when selected DAW launches", isOn: $autoEnable)

            HStack {
                Button("Enable Performance Mode") {
                    ScriptRunner.runScript(named: "enable_performance_mode.sh")
                }
                Button("Restore Normal Mode") {
                    ScriptRunner.runScript(named: "restore_normal_mode.sh")
                }
            }

            Spacer()
        }
        .padding()
        .frame(width: 420, height: 220)
    }

    fileprivate static var window: NSWindow?

    static func show() {
        if let existing = window {
            NSApp.setActivationPolicy(.regular)
            existing.makeKeyAndOrderFront(nil)
            existing.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false)
        newWindow.center()
        newWindow.setFrameAutosaveName("Config")
        newWindow.contentView = NSHostingView(rootView: ConfigWindow())
        NSApp.setActivationPolicy(.regular)
        newWindow.makeKeyAndOrderFront(nil)
        newWindow.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        newWindow.delegate = WindowDelegate.shared
        window = newWindow
    }
}

private class WindowDelegate: NSObject, NSWindowDelegate {
    static let shared = WindowDelegate()
    func windowWillClose(_ notification: Notification) {
        ConfigWindow.window = nil
    }
}
