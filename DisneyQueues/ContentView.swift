import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var store: QueueStore

    var body: some View {
        TabView {
            QueueListView(selection: .single(.disneyland))
                .tabItem {
                    Label("Disneyland", systemImage: "castle")
                }

            QueueListView(selection: .single(.adventureWorld))
                .tabItem {
                    Label("Adventure", systemImage: "sparkles")
                }

            QueueListView(selection: .all)
                .tabItem {
                    Label("All", systemImage: "list.bullet")
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Task {
                    await store.refreshIfNeeded()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(QueueStore())
}
