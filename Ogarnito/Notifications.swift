import UserNotifications

/// Powiadomienie o końcu sesji skupienia — działa też, gdy telefon jest
/// zablokowany albo apka w tle.
enum FocusNotifications {
    private static let id = "ogarnito.focus.done"

    static func schedule(after seconds: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "⏱️ Czas minął!"
            content.body = "Umowa wykonana. Możesz przestać… albo lecieć dalej 😏"
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(1, seconds), repeats: false)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [id])
    }
}
