//
//  HelperService.swift
//  AbletonPerformanceHelper
//
//  Created by Lewis Edwards on 09/08/2025.
//


import Foundation

final class HelperService: NSObject, NSXPCListenerDelegate, HelperXPC {

    // MARK: Listener
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection c: NSXPCConnection) -> Bool {
        c.exportedInterface = NSXPCInterface(with: HelperXPC.self)
        c.exportedObject   = self
        c.resume()
        return true
    }

    // MARK: Protocol implementation
    func ping(_ text: String, reply: @escaping (String) -> Void) { reply(text) }

    func spotlight(_ enable: Bool, reply: @escaping (Int32, String?) -> Void) {
        reply(runSync("/usr/bin/mdutil", ["-i", enable ? "on" : "off", "-a"]), nil)
    }

    func setSystemDaemon(_ label: String, enabled: Bool, reply: @escaping (Int32, String?) -> Void) {
        if enabled {
            _ = runSync("/bin/launchctl", ["enable", "system/\(label)"])
            if FileManager.default.fileExists(atPath: "/System/Library/LaunchDaemons/\(label).plist") {
                reply(runSync("/bin/launchctl", ["bootstrap", "system", "/System/Library/LaunchDaemons/\(label).plist"]), nil)
            } else {
                reply(0, nil)
            }
        } else {
            let a = runSync("/bin/launchctl", ["bootout", "system/\(label)"])
            let b = runSync("/bin/launchctl", ["disable", "system/\(label)"])
            reply(max(a,b), nil)
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
        var code: Int32 = 0
        for (k,v) in kv { code = runSync("/usr/sbin/sysctl", ["-w","\(k)=\(v)"]) }
        reply(code, nil)
    }

    func clearSysctls(_ keys: [String], reply: @escaping (Int32, String?) -> Void) {
        // no-op at runtime; persistent values are handled by installer (optional Advanced tier)
        reply(0, nil)
    }

    // MARK: helpers
    @discardableResult private func runSync(_ tool: String, _ args: [String]) -> Int32 {
        let t = Process()
        t.executableURL = URL(fileURLWithPath: tool)
        t.arguments = args
        do { try t.run() } catch { return -1 }
        t.waitUntilExit()
        return t.terminationStatus
    }
}
