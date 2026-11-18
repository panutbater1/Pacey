import Foundation
import UserNotifications

/// Gentle local notifications for the night in progress.
enum Reminders {
    private static let nextDrinkID = "pacey.nextDrink"
    private static let waterID = "pacey.water"
    private static let homeID = "pacey.home"
    private static let limitID = "pacey.limit"
    private static var allIDs: [String] { [nextDrinkID, waterID, homeID, limitID] }

    /// How long after a drink Pacey suggests water, if none was logged since.
    private static let waterDelay: TimeInterval = 20 * 60

    static func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: allIDs)
        center.removeDeliveredNotifications(withIdentifiers: allIDs)
    }

    /// Call after every change to the night. Replaces whatever was scheduled before.
    static func reschedule(for night: Night, prefs: Preferences) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [nextDrinkID, waterID, homeID])
        guard night.endedAt == nil else { return }

        if prefs.remindNextDrink, let next = night.nextDrinkAt, night.lastDrinkAt != nil {
            schedule(id: nextDrinkID, at: next,
                     title: "Your next drink fits your plan now",
                     body: "No rush. Whenever you're ready.")
        }

        if prefs.remindWater, let lastDrink = night.lastDrinkAt {
            let lastWater = night.waterEntries.last?.timestamp ?? .distantPast
            if lastWater < lastDrink {
                schedule(id: waterID, at: lastDrink.addingTimeInterval(waterDelay),
                         title: "Water time",
                         body: "A glass of water now keeps the night feeling good.")
            }
        }

        if prefs.remindHomeTime {
            let homeByText = night.homeBy.formatted(date: .omitted, time: .shortened)
            schedule(id: homeID, at: night.homeBy.addingTimeInterval(-15 * 60),
                     title: "Heading home soon?",
                     body: "You planned to be home by \(homeByText).")
        }
    }

    /// A kind nudge right away when a drink reaches or passes the plan. `over` is 0 at the plan.
    static func notifyLimit(over: Int, nextDrinkName: String) {
        let message = Pacing.limitMessage(over: over, next: nextDrinkName)
        schedule(id: limitID, at: Date().addingTimeInterval(1.5), title: message.title, body: message.body)
    }

    private static func schedule(id: String, at date: Date, title: String, body: String) {
        let delay = date.timeIntervalSinceNow
        guard delay > 1 else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        )
    }
}

/// Shows Pacey's notifications as banners even while the app is open.
final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationPresenter()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
