import Foundation

public let kHelperMachServiceName = "com.maas1ve.AbletonPerformanceHelper.helper"

@objc public protocol HelperXPC {
    func spotlight(_ enable: Bool, reply: @escaping (Int32, String?) -> Void)
    func setSystemDaemon(_ label: String, enabled: Bool, reply: @escaping (Int32, String?) -> Void)
    func applyPMSetPreset(_ preset: String, reply: @escaping (Int32, String?) -> Void)
    func applySysctls(_ kv: [String:String], reply: @escaping (Int32, String?) -> Void)
    func clearSysctls(_ keys: [String], reply: @escaping (Int32, String?) -> Void)
    func ping(_ text: String, reply: @escaping (String) -> Void)
}
