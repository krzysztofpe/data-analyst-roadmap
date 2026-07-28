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
    /// Realnie przeskupione minuty. Opcjonalne, bo zapisy ze starszych wersji
    /// tego pola nie mają — a brak klucza wywaliłby dekodowanie całego pliku.
    var focusMinutes: Int?

    var nextStep: TaskStep? { steps.first { !$0.done } }
    var doneStepsCount: Int { steps.filter(\.done).count }
    var focusTime: Int { focusMinutes ?? 0 }
}

struct Habit: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    /// Dni wykonania jako klucze "yyyy-MM-dd" — proste i odporne na strefy czasowe.
    var doneDays: Set<String> = []
}

/// Dzienny check-in dbania o siebie: posiłki, woda i minuty skupienia.
struct DayCare: Codable, Hashable {
    var meals: Set<String> = []
    var water: Int = 0
    /// Opcjonalne z tego samego powodu co `focusMinutes` w zadaniu.
    var focus: Int?
}

// MARK: - Czas

enum TimeText {
    /// „45 min", „1 h", „2 h 15 min" — krótko i po ludzku.
    static func minutes(_ total: Int) -> String {
        if total < 60 { return "\(total) min" }
        let h = total / 60, m = total % 60
        return m == 0 ? "\(h) h" : "\(h) h \(m) min"
    }
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

// MARK: - Pieniądze

enum Money {
    /// Waluta z ustawień telefonu — apka ma działać tak samo dobrze
    /// w Warszawie, jak w Berlinie czy Chicago.
    static var code: String {
        Locale.current.currency?.identifier ?? "PLN"
    }
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
    /// Wibracje da się wyłączyć — dla części osób są rozpraszaczem, nie nagrodą.
    static var enabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsOn") as? Bool ?? true
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Zwijana sekcja

/// Lekka, w pełni sterowana zwijka — własna zamiast DisclosureGroup, żeby
/// wyglądała spójnie z resztą ciemnego motywu.
struct CollapsibleSection<Content: View>: View {
    let title: String
    let count: Int
    @Binding var isExpanded: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(duration: 0.3)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("\(title) (\(count))")
                        .font(.caption.bold())
                        .kerning(1.1)
                        .foregroundColor(.appMuted)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.bold())
                        .foregroundColor(.appMuted)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
            }
        }
    }
}
