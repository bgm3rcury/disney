import Foundation

struct QueueAPI {
    func fetchAttractions(for park: Park) async throws -> [Attraction] {
        let request = URLRequest(url: park.apiURL, timeoutInterval: 20)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw QueueAPIError.badResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(Self.decodeDate)
        let payload = try decoder.decode(QueueTimesResponse.self, from: data)
        return payload.attractions(for: park)
    }

    private static func decodeDate(decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = isoFormatter.date(from: value) {
            return date
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: value) {
            return date
        }

        let fallback = DateFormatter()
        fallback.locale = Locale(identifier: "en_US_POSIX")
        fallback.dateFormat = "yyyy-MM-dd HH:mm:ss"

        if let date = fallback.date(from: value) {
            return date
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported date: \(value)")
    }
}

enum QueueAPIError: Error {
    case badResponse
}

struct QueueTimesResponse: Decodable {
    let lands: [LandResponse]
    let rides: [RideResponse]?

    func attractions(for park: Park) -> [Attraction] {
        let landAttractions = lands.flatMap { land in
            land.rides.map { ride in
                ride.attraction(for: park, landName: land.name)
            }
        }

        let topLevelAttractions = (rides ?? []).map { ride in
            ride.attraction(for: park, landName: "Other")
        }

        return landAttractions + topLevelAttractions
    }
}

struct LandResponse: Decodable {
    let name: String
    let rides: [RideResponse]
}

struct RideResponse: Decodable {
    let id: Int
    let name: String
    let isOpen: Bool
    let waitTime: Int
    let lastUpdated: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isOpen = "is_open"
        case waitTime = "wait_time"
        case lastUpdated = "last_updated"
    }

    func attraction(for park: Park, landName: String) -> Attraction {
        Attraction(
            id: "\(park.rawValue)-\(id)",
            rideID: id,
            park: park,
            landName: landName,
            name: name,
            isOpen: isOpen,
            waitTime: waitTime,
            lastUpdated: lastUpdated
        )
    }
}
