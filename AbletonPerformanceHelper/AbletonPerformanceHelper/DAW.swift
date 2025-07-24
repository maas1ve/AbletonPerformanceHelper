import Foundation

enum DAW: String, CaseIterable, Identifiable {
    case abletonLive = "Ableton Live"
    case logicPro = "Logic Pro"
    case flStudio = "FL Studio"
    case cubase = "Cubase"
    case proTools = "Pro Tools"
    case reaper = "Reaper"
    case bitwigStudio = "Bitwig Studio"

    var id: String { rawValue }
}
