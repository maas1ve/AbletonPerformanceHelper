import Foundation

final class AdminHelperClient {
    static let shared = AdminHelperClient()
    private var connection: NSXPCConnection?

    private func connect() {
        let c = NSXPCConnection(machServiceName: kHelperMachServiceName, options: .privileged)
        c.remoteObjectInterface = NSXPCInterface(with: HelperXPC.self)
        c.invalidationHandler = { [weak self] in self?.connection = nil }
        c.resume()
        connection = c
    }

    func isReachable() -> Bool {
        if connection == nil { connect() }
        guard let proxy = connection?.remoteObjectProxy as? HelperXPC else { return false }
        let sem = DispatchSemaphore(value: 0)
        var ok = false
        proxy.ping("hi") { resp in ok = (resp == "hi"); sem.signal() }
        _ = sem.wait(timeout: .now() + 1.0)
        return ok
    }

    private func proxy() throws -> HelperXPC {
        if connection == nil { connect() }
        guard let p = connection?.remoteObjectProxyWithErrorHandler({ _ in }) as? HelperXPC else {
            throw NSError(domain: "AdminHelperClient", code: -1, userInfo: [NSLocalizedDescriptionKey:"No helper connection"])
        }
        return p
    }

    // MARK: Calls
    func setSpotlight(_ enable: Bool, completion: @escaping (Int32, String?) -> Void) {
        do { try proxy().spotlight(enable, reply: completion) } catch { completion(-1, error.localizedDescription) }
    }
    func setSystemDaemon(label: String, enabled: Bool, completion: @escaping (Int32, String?) -> Void) {
        do { try proxy().setSystemDaemon(label, enabled: enabled, reply: completion) } catch { completion(-1, error.localizedDescription) }
    }
    func applyPMSetPreset(_ preset: String, completion: @escaping (Int32, String?) -> Void) {
        do { try proxy().applyPMSetPreset(preset, reply: completion) } catch { completion(-1, error.localizedDescription) }
    }
    func applySysctls(_ kv: [String:String], completion: @escaping (Int32, String?) -> Void) {
        do { try proxy().applySysctls(kv, reply: completion) } catch { completion(-1, error.localizedDescription) }
    }
    func clearSysctls(_ keys: [String], completion: @escaping (Int32, String?) -> Void) {
        do { try proxy().clearSysctls(keys, reply: completion) } catch { completion(-1, error.localizedDescription) }
    }
}
