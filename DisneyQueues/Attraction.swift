import Foundation

struct Attraction: Identifiable, Equatable {
    let id: String
    let rideID: Int
    let park: Park
    let landName: String
    let name: String
    let isOpen: Bool
    let waitTime: Int
    let lastUpdated: Date?

    var favoriteKey: String {
        "\(park.rawValue)-\(rideID)"
    }

    var crowdLevel: CrowdLevel {
        if !isOpen {
            return .closed
        }

        switch waitTime {
        case 0...15:
            return .low
        case 16...40:
            return .moderate
        case 41...70:
            return .busy
        default:
            return .veryBusy
        }
    }
}

enum CrowdLevel: String {
    case low = "Low"
    case moderate = "Moderate"
    case busy = "Busy"
    case veryBusy = "Very Busy"
    case closed = "Closed"
}
