import SwiftUI

@main
struct DisneyQueuesApp: App {
    @StateObject private var store = QueueStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
