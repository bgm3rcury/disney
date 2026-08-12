import Foundation

enum Park: Int, CaseIterable, Identifiable {
    case disneyland = 4
    case adventureWorld = 28

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .disneyland:
            return "Disneyland Park"
        case .adventureWorld:
            return "Disney Adventure World"
        }
    }

    var shortName: String {
        switch self {
        case .disneyland:
            return "Disneyland"
        case .adventureWorld:
            return "Adventure World"
        }
    }

    var apiURL: URL {
        URL(string: "https://queue-times.com/parks/\(rawValue)/queue_times.json")!
    }
}
