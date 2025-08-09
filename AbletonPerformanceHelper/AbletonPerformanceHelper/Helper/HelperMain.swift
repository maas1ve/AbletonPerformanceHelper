//
//  HelperMain.swift
//  AbletonPerformanceHelper
//
//  Created by Lewis Edwards on 09/08/2025.
//


import Foundation

final class HelperMain {
    private let listener = NSXPCListener(machServiceName: kHelperMachServiceName)
    private let service  = HelperService()

    func run() {
        listener.delegate = service
        listener.resume()
        RunLoop.current.run()
    }
}

@main
struct Entry {
    static func main() { HelperMain().run() }
}
