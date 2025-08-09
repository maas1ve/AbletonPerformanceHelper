import Foundation

final class HelperService: NSObject, NSXPCListenerDelegate, HelperXPC {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection c: NSXPCConnection) -> Bool {
        c.exportedInterface = NSXPCInterface(with: HelperXPC.self)
        c.exportedObject   = self
        c.resume()
        return true
    }

    func ping(_ text: String, reply: @escaping (String) -> Void) { reply(text) }

    func spotlight(_ enable: Bool, reply: @escaping (Int32, String?) -> Void) {
        reply(run("/usr/bin/mdutil", ["-i", enable ? "on" : "off", "-a"]), nil)
    }

    func setSystemDaemon(_ label: String, enabled: Bool, reply: @escaping (Int32, String?) -> Void) {
        if enabled {
            _ = run("/bin/launchctl", ["enable", "system/\(label)"])
            if FileManager.default.fileExists(atPath: "/System/Library/LaunchDaemons/\(label).plist") {
                reply(run("/bin/launchctl", ["bootstrap","system","/System/Library/LaunchDaemons/\(label).plist"]), nil)
            } else { reply(0, nil) }
        } else {
            let a = run("/bin/launchctl", ["bootout","system/\(label)"])
            let b = run("/bin/launchctl", ["disable","system/\(label)"])
            reply(max(a,b), nil)
        }
    }

    func applyPMSetPreset(_ preset: String, reply: @escaping (Int32, String?) -> Void) {
        let sets: [[String]] = (preset == "audio")
        ? [["-c","sleep","0"],["-c","disksleep","0"],["-c","displaysleep","30"],["-c","hibernatemode","0"],["-c","standby","0"],["-c","autopoweroff","0"],["-c","powernap","0"]]
        : [["-c","sleep","10"],["-c","disksleep","10"],["-c","displaysleep","10"],["-c","hibernatemode","3"],["-c","standby","1"],["-c","autopoweroff","1"],["-c","powernap","1"]]
        var code: Int32 = 0
        for args in sets { code = run("/usr/bin/pmset", args) }
        reply(code, nil)
    }

    func applySysctls(_ kv: [String : String], reply: @escaping (Int32, String?) -> Void) {
        var code: Int32 = 0
        for (k,v) in kv { code = run("/usr/sbin/sysctl", ["-w","\(k)=\(v)"]) }
        reply(code, nil)
    }

    func clearSysctls(_ keys: [String], reply: @escaping (Int32, String?) -> Void) {
        reply(0, nil) // runtime only; persistent reset handled elsewhere
    }

    @discardableResult private func run(_ tool: String, _ args: [String]) -> Int32 {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: tool)
        p.arguments = args
        do { try p.run() } catch { return -1 }
        p.waitUntilExit()
        return p.terminationStatus
    }
}
