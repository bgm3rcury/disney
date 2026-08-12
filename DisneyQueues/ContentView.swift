import SwiftUI

struct ContentView: View {
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
    }
}

#Preview {
    ContentView()
        .environmentObject(QueueStore())
}
