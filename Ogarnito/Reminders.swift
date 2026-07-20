import Foundation
import UserNotifications

/// Codzienne przypomnienia — zewnętrzna pamięć dla ADHD-mózgu.
enum DailyReminder: String, CaseIterable {
    case morning = "ogarnito.reminder.morning"
    case meal = "ogarnito.reminder.meal"
    case evening = "ogarnito.reminder.evening"

    var title: String {
        switch self {
        case .morning: return "☀️ Zaplanuj dzień"
        case .meal: return "🍽️ Przerwa na jedzenie"
        case .evening: return "🌙 Domknij dzień"
        }
    }

    var body: String {
        switch self {
        case .morning: return "Wybierz żabę 🐸 i trzy zadania. Reszta to bonus."
        case .meal: return "Serio — czas coś zjeść. Odhacz posiłek w Ogarnito."
        case .evening: return "Sprawdź nawyki i zobacz dzisiejsze zwycięstwa. Było lepiej, niż myślisz."
        }
    }

    /// Sekundy od północy → codzienne powiadomienie o tej godzinie.
    func schedule(secondsFromMidnight: Double) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = self.title
            content.body = self.body
            content.sound = .default
            var components = DateComponents()
            components.hour = Int(secondsFromMidnight) / 3600
            components.minute = (Int(secondsFromMidnight) % 3600) / 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            center.removePendingNotificationRequests(withIdentifiers: [self.rawValue])
            center.add(UNNotificationRequest(identifier: self.rawValue,
                                             content: content, trigger: trigger))
        }
    }

    func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [rawValue])
    }
}
