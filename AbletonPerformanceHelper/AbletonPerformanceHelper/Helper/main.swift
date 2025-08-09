import Foundation

final class ServiceDelegate: NSObject, NSXPCListenerDelegate, HelperXPC {
    private let listener = NSXPCListener(machServiceName: kHelperMachServiceName)

    override init() { super.init(); listener.delegate = self }
    func run() { listener.resume(); RunLoop.current.run() }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection c: NSXPCConnection) -> Bool {
        c.exportedInterface = NSXPCInterface(with: HelperXPC.self)
        c.exportedObject = self
        c.resume()
        return true
    }

    // MARK: API
    func ping(_ text: String, reply: @escaping (String) -> Void) { reply(text) }

    func spotlight(_ enable: Bool, reply: @escaping (Int32, String?) -> Void) {
        run("/usr/bin/mdutil", ["-i", enable ? "on" : "off", "-a"], reply)
    }

    func setSystemDaemon(_ label: String, enabled: Bool, reply: @escaping (Int32, String?) -> Void) {
        if enabled {
            _ = runSync("/bin/launchctl", ["enable", "system/\(label)"])
            if FileManager.default.fileExists(atPath: "/System/Library/LaunchDaemons/\(label).plist") {
                run("/bin/launchctl", ["bootstrap", "system", "/System/Library/LaunchDaemons/\(label).plist"], reply)
                return
            }
            reply(0, nil)
        } else {
            let c1 = runSync("/bin/launchctl", ["bootout", "system/\(label)"])
            let c2 = runSync("/bin/launchctl", ["disable",  "system/\(label)"])
            reply(max(c1,c2), nil)
        }
    }

    func applyPMSetPreset(_ preset: String, reply: @escaping (Int32, String?) -> Void) {
        let cmds: [[String]] = (preset == "audio")
        ? [["-c","sleep","0"],["-c","disksleep","0"],["-c","displaysleep","30"],["-c","hibernatemode","0"],["-c","standby","0"],["-c","autopoweroff","0"],["-c","powernap","0"]]
        : [["-c","sleep","10"],["-c","disksleep","10"],["-c","displaysleep","10"],["-c","hibernatemode","3"],["-c","standby","1"],["-c","autopoweroff","1"],["-c","powernap","1"]]
        var last: Int32 = 0
        for a in cmds { last = runSync("/usr/bin/pmset", a) }
        reply(last, nil)
    }

    func applySysctls(_ kv: [String:String], reply: @escaping (Int32, String?) -> Void) {
        var exitCode: Int32 = 0
        for (k,v) in kv { let c = runSync("/usr/sbin/sysctl", ["-w","\(k)=\(v)"]); if c != 0 { exitCode = c } }
        reply(exitCode, nil)
    }

    func clearSysctls(_ keys: [String], reply: @escaping (Int32, String?) -> Void) {
        reply(0, nil) // runtime “unset” varies; keep simple
    }

    // MARK: proc helpers
    private func run(_ tool: String, _ args: [String], _ reply: @escaping (Int32, String?) -> Void) {
        DispatchQueue.global().async { reply(self.runSync(tool, args), nil) }
    }
    @discardableResult private func runSync(_ tool: String, _ args: [String]) -> Int32 {
        let t = Process(); t.executableURL = URL(fileURLWithPath: tool); t.arguments = args
        do { try t.run() } catch { return -1 }
        t.waitUntilExit(); return t.terminationStatus
    }
}

ServiceDelegate().run()
