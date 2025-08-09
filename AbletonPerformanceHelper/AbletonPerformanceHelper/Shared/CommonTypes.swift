//
//  DAW.swift
//  AbletonPerformanceHelper
//
//  Created by Lewis Edwards on 09/08/2025.
//


import Foundation

public enum DAW: String, CaseIterable, Identifiable {
    case abletonLive = "Ableton Live"
    case logicPro    = "Logic Pro"
    case proTools    = "Pro Tools"
    case cubase      = "Cubase"
    case studioOne   = "Studio One"
    case reaper      = "REAPER"
    public var id: String { rawValue }
}

public enum APHError: Error {
    case helperNotReachable
    case operationFailed(code: Int32, message: String?)
}
