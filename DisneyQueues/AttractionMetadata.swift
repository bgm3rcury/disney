import Foundation

enum AttractionCategory: String, CaseIterable, Identifiable, Codable {
    case all
    case chillRide
    case coasters
    case bigThrills
    case family
    case walkthrough
    case showsMeetups
    case singleRider

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All Categories"
        case .chillRide:
            return "Chill Ride"
        case .coasters:
            return "Coasters"
        case .bigThrills:
            return "Big Thrills"
        case .family:
            return "Family"
        case .walkthrough:
            return "Walkthrough"
        case .showsMeetups:
            return "Shows/Meetups"
        case .singleRider:
            return "Single Rider"
        }
    }
}

struct AttractionMetadata: Codable, Equatable {
    let parkID: Int
    let rideID: Int
    let name: String
    let simpleCategories: [AttractionCategory]
    let officialTags: [String]
    let isCoaster: Bool
    let parentRideID: Int?
    let imageName: String

    enum CodingKeys: String, CodingKey {
        case parkID
        case rideID
        case name
        case simpleCategories
        case officialTags
        case isCoaster
        case parentRideID
        case imageName
    }
}

final class AttractionMetadataStore {
    static let shared = AttractionMetadataStore()

    private let byRideKey: [String: AttractionMetadata]
    private let byNameKey: [String: AttractionMetadata]

    init(bundle: Bundle = .main) {
        let metadata = Self.loadMetadata(bundle: bundle)
        self.byRideKey = Dictionary(uniqueKeysWithValues: metadata.map { (Self.rideKey(parkID: $0.parkID, rideID: $0.rideID), $0) })
        self.byNameKey = Dictionary(metadata.map { (Self.nameKey(parkID: $0.parkID, name: $0.name), $0) }, uniquingKeysWith: { first, _ in first })
    }

    func metadata(for attraction: Attraction) -> AttractionMetadata? {
        byRideKey[Self.rideKey(parkID: attraction.park.rawValue, rideID: attraction.rideID)]
            ?? byNameKey[Self.nameKey(parkID: attraction.park.rawValue, name: attraction.name)]
    }

    private static func loadMetadata(bundle: Bundle) -> [AttractionMetadata] {
        guard let url = bundle.url(forResource: "AttractionMetadata", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let metadata = try? JSONDecoder().decode([AttractionMetadata].self, from: data) else {
            return []
        }

        return metadata
    }

    private static func rideKey(parkID: Int, rideID: Int) -> String {
        "\(parkID)-\(rideID)"
    }

    private static func nameKey(parkID: Int, name: String) -> String {
        "\(parkID)-\(normalize(name))"
    }

    static func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "™", with: "")
            .replacingOccurrences(of: "®", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "’", with: "'")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
            .lowercased()
    }
}

extension Attraction {
    var metadata: AttractionMetadata? {
        AttractionMetadataStore.shared.metadata(for: self)
    }

    var displayCategories: [AttractionCategory] {
        metadata?.simpleCategories ?? fallbackCategories
    }

    var officialTags: [String] {
        metadata?.officialTags ?? []
    }

    var imageName: String? {
        metadata?.imageName
    }

    var isCoaster: Bool {
        metadata?.isCoaster ?? fallbackCategories.contains(.coasters)
    }

    func matches(category: AttractionCategory) -> Bool {
        category == .all || displayCategories.contains(category)
    }

    private var fallbackCategories: [AttractionCategory] {
        let normalized = AttractionMetadataStore.normalize(name)

        if normalized.contains("single-rider") {
            return [.singleRider]
        }

        if normalized.contains("coaster") || normalized.contains("hyperspace-mountain") || normalized.contains("indiana-jones") || normalized.contains("flight-force") {
            return [.coasters, .bigThrills]
        }

        return [.family]
    }
}
