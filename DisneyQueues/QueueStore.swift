import Foundation

@MainActor
final class QueueStore: ObservableObject {
    static let refreshInterval: TimeInterval = 300

    @Published private(set) var attractionsByPark: [Park: [Attraction]] = [:]
    @Published private(set) var lastRefresh: Date?
    @Published private(set) var nextRefresh: Date = Date().addingTimeInterval(refreshInterval)
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var favorites: Set<String> = []

    private let api: QueueAPI
    private var refreshTask: Task<Void, Never>?
    private let favoritesKey = "favoriteAttractions"

    init(api: QueueAPI = QueueAPI()) {
        self.api = api
        self.favorites = Set(UserDefaults.standard.stringArray(forKey: favoritesKey) ?? [])
    }

    deinit {
        refreshTask?.cancel()
    }

    func start() {
        guard refreshTask == nil else {
            return
        }

        refreshTask = Task {
            await refresh()

            while !Task.isCancelled {
                let seconds = max(1, Int(nextRefresh.timeIntervalSinceNow))
                try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
                await refresh()
            }
        }
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil

        do {
            async let disneyland = api.fetchAttractions(for: .disneyland)
            async let adventureWorld = api.fetchAttractions(for: .adventureWorld)

            attractionsByPark[.disneyland] = try await disneyland
            attractionsByPark[.adventureWorld] = try await adventureWorld
            lastRefresh = Date()
            nextRefresh = Date().addingTimeInterval(Self.refreshInterval)
        } catch {
            errorMessage = "Could not refresh queue times. Showing the latest available data."
            nextRefresh = Date().addingTimeInterval(60)
        }

        isLoading = false
    }

    func attractions(for selection: ParkSelection) -> [Attraction] {
        switch selection {
        case .single(let park):
            return attractionsByPark[park, default: []]
        case .all:
            return Park.allCases.flatMap { attractionsByPark[$0, default: []] }
        }
    }

    func isFavorite(_ attraction: Attraction) -> Bool {
        favorites.contains(attraction.favoriteKey)
    }

    func toggleFavorite(_ attraction: Attraction) {
        if favorites.contains(attraction.favoriteKey) {
            favorites.remove(attraction.favoriteKey)
        } else {
            favorites.insert(attraction.favoriteKey)
        }

        UserDefaults.standard.set(Array(favorites).sorted(), forKey: favoritesKey)
    }
}

enum ParkSelection: Identifiable, Hashable {
    case single(Park)
    case all

    var id: String {
        switch self {
        case .single(let park):
            return String(park.rawValue)
        case .all:
            return "all"
        }
    }

    var title: String {
        switch self {
        case .single(let park):
            return park.name
        case .all:
            return "All Parks"
        }
    }

    var tabTitle: String {
        switch self {
        case .single(let park):
            return park.shortName
        case .all:
            return "All"
        }
    }
}
