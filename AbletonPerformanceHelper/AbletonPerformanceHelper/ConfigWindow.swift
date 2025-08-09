import SwiftUI
import AppKit

struct ConfigWindowView: View {
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
                    _ = ScriptRunner.runScript(named: "enable_performance_mode.sh")
                }
                Button("Restore Normal Mode") {
                    _ = ScriptRunner.runScript(named: "restore_normal_mode.sh")
                }
            }

            Spacer()
        }
        .padding()
        .frame(width: 420, height: 220)
    }
}

final class ConfigWindow {
    private static var window: NSWindow?

    static func show() {
        if let win = window {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 220),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered, defer: false
        )
        win.title = "Ableton Performance Helper — Preferences"
        win.center()
        win.isReleasedWhenClosed = false
        win.contentView = NSHostingView(rootView: ConfigWindowView())
        win.delegate = ConfigWindowDelegate.shared

        window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    fileprivate static func hide() { window?.orderOut(nil) }
}

final class ConfigWindowDelegate: NSObject, NSWindowDelegate {
    static let shared = ConfigWindowDelegate()
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        ConfigWindow.hide()
        return false
    }
}
