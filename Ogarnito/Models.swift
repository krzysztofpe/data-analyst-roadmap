import SwiftUI
import UIKit

// MARK: - Model danych

struct TaskStep: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    var done = false
}

/// Ile mocy wymaga zadanie — żeby dało się dopasować robotę do stanu baterii.
enum EnergyLevel: String, Codable, Hashable {
    case high, low

    var badge: String { self == .high ? "⚡" : "🪫" }
}

struct TodoTask: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var steps: [TaskStep] = []
    var done = false
    var isFrog = false
    var doneAt: Date?
    var createdAt = Date()
    var energy: EnergyLevel?

    var nextStep: TaskStep? { steps.first { !$0.done } }
    var doneStepsCount: Int { steps.filter(\.done).count }
}

struct Habit: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    /// Dni wykonania jako klucze "yyyy-MM-dd" — proste i odporne na strefy czasowe.
    var doneDays: Set<String> = []
}

/// Dzienny check-in dbania o siebie: posiłki i woda.
struct DayCare: Codable, Hashable {
    var meals: Set<String> = []
    var water: Int = 0
}

/// Impuls zakupowy z 48-godzinną poczekalnią: impuls mija, kasa zostaje.
struct ImpulseItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var price: Double
    var createdAt = Date()
    var decision: Decision?
    var decidedAt: Date?

    enum Decision: String, Codable {
        case bought, skipped
    }

    var readyAt: Date { createdAt.addingTimeInterval(48 * 3600) }
    var isReady: Bool { Date() >= readyAt }
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

    /// Indeksowane komponentem .weekday - 1 (niedziela = 0).
    static let shortWeekdays = ["nd", "pn", "wt", "śr", "cz", "pt", "sb"]
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

// MARK: - Wspólne elementy UI

/// Tło aplikacji — delikatny pionowy gradient zamiast płaskiego koloru.
struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(hex: 0x16162B), Color(hex: 0x0B0B14)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

/// Sprężysty przycisk — lekkie skurczenie przy wciśnięciu.
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}

struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .kerning(1.2)
            .foregroundColor(.appMuted)
            .textCase(.uppercase)
    }
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
