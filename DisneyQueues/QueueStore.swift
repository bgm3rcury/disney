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
    @Published private(set) var notificationsEnabled = false

    private let api: QueueAPI
    private let notificationService: QueueNotificationService
    private var refreshTask: Task<Void, Never>?
    private let favoritesKey = "favoriteAttractions"

    init(api: QueueAPI = QueueAPI()) {
        self.api = api
        let notificationService = QueueNotificationService()
        self.notificationService = notificationService
        self.favorites = Set(UserDefaults.standard.stringArray(forKey: favoritesKey) ?? [])
        self.notificationsEnabled = notificationService.notificationsEnabled
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
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await refreshIfNeeded()
            }
        }
    }

    func refreshIfNeeded() async {
        guard !isLoading, Date() >= nextRefresh else {
            return
        }

        await refresh()
    }

    func refresh() async {
        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            async let disneyland = api.fetchAttractions(for: .disneyland)
            async let adventureWorld = api.fetchAttractions(for: .adventureWorld)

            attractionsByPark[.disneyland] = try await disneyland
            attractionsByPark[.adventureWorld] = try await adventureWorld
            let refreshedAt = Date()
            lastRefresh = refreshedAt
            nextRefresh = refreshedAt.addingTimeInterval(Self.refreshInterval)
            await notificationService.evaluate(attractions: allAttractions, favorites: favorites)
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
            return allAttractions
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
        Task {
            await notificationService.evaluate(attractions: allAttractions, favorites: favorites)
        }
    }

    func setNotificationsEnabled(_ enabled: Bool) {
        notificationService.notificationsEnabled = enabled
        notificationsEnabled = enabled

        if enabled {
            Task {
                await notificationService.requestAuthorizationIfNeeded()
                await notificationService.evaluate(attractions: allAttractions, favorites: favorites)
            }
        }
    }

    private var allAttractions: [Attraction] {
        Park.allCases.flatMap { attractionsByPark[$0, default: []] }
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
