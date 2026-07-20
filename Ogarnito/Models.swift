import SwiftUI
import UIKit

// MARK: - Model danych

struct TaskStep: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    var done = false
}

struct TodoTask: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var steps: [TaskStep] = []
    var done = false
    var isFrog = false
    var doneAt: Date?
    var createdAt = Date()

    var nextStep: TaskStep? { steps.first { !$0.done } }
    var doneStepsCount: Int { steps.filter(\.done).count }
}

struct Habit: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    /// Dni wykonania jako klucze "yyyy-MM-dd" — proste i odporne na strefy czasowe.
    var doneDays: Set<String> = []
}

// MARK: - Klucze dni

enum Dates {
    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        return f
    }()

    static func dayKey(_ date: Date = Date()) -> String {
        dayFormatter.string(from: date)
    }
}

// MARK: - Kolory motywu

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    static let appBg = Color(hex: 0x0F0F1A)
    static let appCard = Color(hex: 0x1A1A2B)
    static let appCard2 = Color(hex: 0x232338)
    static let appLine = Color(hex: 0x2E2E48)
    static let appAccent = Color(hex: 0xA78BFA)
    static let appAccentDark = Color(hex: 0x7C3AED)
    static let appMuted = Color(hex: 0x9A9AB5)
    static let appGood = Color(hex: 0x34D399)
    static let appWarn = Color(hex: 0xFBBF24)
    static let appFrog = Color(hex: 0x4ADE80)
}

// MARK: - Haptyka

enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
