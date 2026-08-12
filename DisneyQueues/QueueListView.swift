import SwiftUI

struct QueueListView: View {
    let selection: ParkSelection

    @EnvironmentObject private var store: QueueStore
    @State private var sortMode: SortMode = .openThenShortest
    @State private var favoritesOnly = false
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    RefreshHeaderView(
                        isLoading: store.isLoading,
                        lastRefresh: store.lastRefresh,
                        nextRefresh: store.nextRefresh,
                        now: now,
                        errorMessage: store.errorMessage
                    ) {
                        Task {
                            await store.refresh()
                        }
                    }
                }

                Section {
                    Picker("Sort", selection: $sortMode) {
                        ForEach(SortMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }

                    Toggle("Favorites only", isOn: $favoritesOnly)
                }

                Section {
                    if filteredAttractions.isEmpty {
                        EmptyQueueView(favoritesOnly: favoritesOnly)
                    } else {
                        ForEach(filteredAttractions) { attraction in
                            AttractionRow(
                                attraction: attraction,
                                isFavorite: store.isFavorite(attraction)
                            ) {
                                store.toggleFavorite(attraction)
                            }
                        }
                    }
                } footer: {
                    Text("Powered by Queue-Times.com")
                }
            }
            .navigationTitle(selection.title)
            .refreshable {
                await store.refresh()
            }
            .onReceive(timer) { value in
                now = value
            }
            .task {
                store.start()
            }
        }
    }

    private var filteredAttractions: [Attraction] {
        store.attractions(for: selection)
            .filter { attraction in
                !favoritesOnly || store.isFavorite(attraction)
            }
            .sorted(using: sortMode)
    }
}

private struct EmptyQueueView: View {
    let favoritesOnly: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: favoritesOnly ? "star" : "clock.badge.exclamationmark")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(favoritesOnly ? "No Favorites" : "No Queue Data")
                .font(.headline)

            Text(favoritesOnly ? "Tap the star on an attraction to save it here." : "Pull to refresh or try again in a moment.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
enum SortMode: String, CaseIterable, Identifiable {
    case openThenShortest
    case longest
    case shortest
    case alphabetical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openThenShortest:
            return "Open first"
        case .longest:
            return "Longest wait"
        case .shortest:
            return "Shortest wait"
        case .alphabetical:
            return "A-Z"
        }
    }
}

private extension Array where Element == Attraction {
    func sorted(using sortMode: SortMode) -> [Attraction] {
        sorted { lhs, rhs in
            switch sortMode {
            case .openThenShortest:
                if lhs.isOpen != rhs.isOpen {
                    return lhs.isOpen && !rhs.isOpen
                }

                if lhs.waitTime != rhs.waitTime {
                    return lhs.waitTime < rhs.waitTime
                }

                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .longest:
                if lhs.waitTime != rhs.waitTime {
                    return lhs.waitTime > rhs.waitTime
                }

                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .shortest:
                if lhs.isOpen != rhs.isOpen {
                    return lhs.isOpen && !rhs.isOpen
                }

                if lhs.waitTime != rhs.waitTime {
                    return lhs.waitTime < rhs.waitTime
                }

                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .alphabetical:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }
    }
}
