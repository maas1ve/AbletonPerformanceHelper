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

    static func show() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 150),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false)
        window.center()
        window.setFrameAutosaveName("Config")
        window.contentView = NSHostingView(rootView: ConfigWindow())
        window.makeKeyAndOrderFront(nil)
    }
}
