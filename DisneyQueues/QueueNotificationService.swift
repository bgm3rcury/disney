import Foundation
import UserNotifications

@MainActor
final class QueueNotificationService: ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: Self.notificationsEnabledKey)
        }
    }

    private static let notificationsEnabledKey = "queueNotificationsEnabled"
    private let notifiedBelowBusyKey = "notifiedBelowBusyFavoriteCoasters"
    private var notifiedBelowBusy: Set<String>

    init() {
        self.notificationsEnabled = UserDefaults.standard.object(forKey: Self.notificationsEnabledKey) as? Bool ?? false
        self.notifiedBelowBusy = Set(UserDefaults.standard.stringArray(forKey: notifiedBelowBusyKey) ?? [])
        Task {
            await refreshAuthorizationStatus()
        }
    }

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }

        await refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func evaluate(attractions: [Attraction], favorites: Set<String>) async {
        guard notificationsEnabled else {
            return
        }

        await requestAuthorizationIfNeeded()
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            return
        }

        for attraction in attractions where favorites.contains(attraction.favoriteKey) && attraction.isCoaster {
            let key = attraction.favoriteKey
            let isBelowBusy = attraction.isOpen && attraction.waitTime < 41

            if isBelowBusy && !notifiedBelowBusy.contains(key) {
                await sendBelowBusyNotification(for: attraction)
                notifiedBelowBusy.insert(key)
            } else if !isBelowBusy {
                notifiedBelowBusy.remove(key)
            }
        }

        UserDefaults.standard.set(Array(notifiedBelowBusy).sorted(), forKey: notifiedBelowBusyKey)
    }

    private func sendBelowBusyNotification(for attraction: Attraction) async {
        let content = UNMutableNotificationContent()
        content.title = "Shorter coaster queue"
        content.body = "\(attraction.name) is now \(attraction.waitTime) min at \(attraction.park.shortName)."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "below-busy-\(attraction.favoriteKey)-\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}
