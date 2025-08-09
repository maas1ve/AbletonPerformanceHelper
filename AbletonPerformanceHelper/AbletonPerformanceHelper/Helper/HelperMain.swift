import Foundation

@main
struct Entry {
    static func main() {
        let listener = NSXPCListener(machServiceName: kHelperMachServiceName)
        let svc = HelperService()
        listener.delegate = svc
        listener.resume()
        RunLoop.current.run()
    }
}
