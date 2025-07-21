import SwiftUI

struct ConfigWindow: View {
    @AppStorage("watchedApps") var watchedApps: String = "Ableton Live"

    var body: some View {
        VStack(alignment: .leading) {
            Text("Watched Apps (comma-separated):")
            TextField("e.g. Ableton Live, Logic Pro", text: $watchedApps)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Spacer()
        }
        .padding()
        .frame(width: 300, height: 150)
    }

    private static var window: NSWindow?

    static func show() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 150),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false)
        newWindow.center()
        newWindow.setFrameAutosaveName("Config")
        newWindow.contentView = NSHostingView(rootView: ConfigWindow())
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = newWindow
    }
}
