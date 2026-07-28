import SwiftUI
import Charts

/// Widok „Teraz" — pokazuje JEDNO zadanie i tylko jego następny krok,
/// żeby nie przytłaczać. Serce aplikacji.
struct NowView: View {
    @EnvironmentObject var store: AppStore
    @State private var showStuck = false
    @State private var showLogDone = false
    @State private var doneText = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                greetingHeader
                if store.daysAway >= 2 {
                    welcomeBackCard
                }
                nowCard
                doneTodaySection
                if store.weekStats.contains(where: { $0.count > 0 }) {
                    weekCard
                }
            }
            .padding(16)
        }
        .background(AppBackground())
        .buttonStyle(ScaleButtonStyle())
    }

    private var greetingHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.title3.bold())
                Text(Date(), format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.caption)
                    .foregroundColor(.appMuted)
            }
            Spacer()
            if store.openTaskCount > 0 {
                energyPicker
            }
        }
    }

    /// Filtr mocy: pokaż zadania pasujące do obecnego stanu baterii.
    private var energyPicker: some View {
        HStack(spacing: 6) {
            energyChip(.high)
            energyChip(.low)
        }
    }

    private func energyChip(_ level: EnergyLevel) -> some View {
        let selected = store.currentEnergy == level
        return Button {
            withAnimation(.spring(duration: 0.3)) {
                store.currentEnergy = selected ? nil : level
            }
        } label: {
            Text(level.badge)
                .font(.subheadline)
                .frame(width: 38, height: 38)
                .background(selected ? Color.appAccentDark : Color.appCard2, in: Circle())
                .overlay(Circle().stroke(selected ? Color.appAccent : Color.appLine))
        }
        .accessibilityLabel(level == .high
            ? (selected ? "Wyłącz filtr pełnej energii" : "Pokaż zadania na pełną energię")
            : (selected ? "Wyłącz filtr niskiej energii" : "Pokaż zadania na niską energię"))
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Dzień dobry! ☀️"
        case 12..<18: return "Miłego popołudnia! 🌤️"
        case 18..<23: return "Dobry wieczór! 🌙"
        default: return "Nocna zmiana? 🦉"
        }
    }

    @ViewBuilder
    private var nowCard: some View {
        VStack(spacing: 14) {
            if let task = store.currentTask {
                Text(task.isFrog ? "🐸 ZJEDZ ŻABĘ" : "🎯 TYLKO TO JEDNO")
                    .font(.caption.bold())
                    .kerning(2)
                    .foregroundColor(.appAccent)

                Text(task.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                if let step = task.nextStep {
                    (Text("Następny krok: ").foregroundColor(.appMuted)
                     + Text(step.text).bold())
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                } else if task.steps.isEmpty {
                    Text("Za duże? Rozbij na mikro-kroki — pierwszy ma zająć maks 10 minut.")
                        .font(.subheadline)
                        .foregroundColor(.appMuted)
                        .multilineTextAlignment(.center)
                }

                Button {
                    if let step = task.nextStep {
                        store.toggleStep(taskID: task.id, stepID: step.id)
                    } else {
                        store.toggleTask(task.id)
                    }
                } label: {
                    Text(task.nextStep != nil ? "Krok zrobiony ✓" : "Zrobione ✓")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appGood, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundColor(Color(hex: 0x06281C))
                }

                HStack(spacing: 10) {
                    ghostButton("🔪 Rozbij") { store.selectedTab = .tasks }
                    ghostButton("⏱️ Fokus") { store.selectedTab = .timer }
                    if store.openTaskCount > 1 {
                        ghostButton("↷ Pomiń") {
                            withAnimation(.spring(duration: 0.35)) {
                                store.skipCurrentTask()
                            }
                        }
                    }
                }
                .font(.subheadline.bold())

                HStack(spacing: 18) {
                    Button {
                        showStuck = true
                    } label: {
                        Text("😩 Nie mogę zacząć")
                            .font(.footnote.bold())
                            .foregroundColor(.appMuted)
                    }
                    if store.openTaskCount > 1 {
                        Button {
                            withAnimation(.spring(duration: 0.35)) {
                                store.pickRandomTask()
                            }
                        } label: {
                            Text("🎲 Wylosuj")
                                .font(.footnote.bold())
                                .foregroundColor(.appMuted)
                        }
                    }
                }
                .padding(.top, 2)
                .confirmationDialog(
                    "Utknięcie to nie lenistwo — mózg potrzebuje rozbiegu. Wybierz odblokowanie:",
                    isPresented: $showStuck,
                    titleVisibility: .visible
                ) {
                    Button("🤏 2 minuty byle jak — start!") {
                        store.timerRequest = 2
                        store.selectedTab = .timer
                    }
                    Button("🔪 Rozbij na śmiesznie mały krok") {
                        store.selectedTab = .tasks
                    }
                    Button("🌬️ Najpierw wydech") {
                        store.showBreathing = true
                    }
                    Button("Anuluj", role: .cancel) {}
                }
            } else {
                Text("TERAZ")
                    .font(.caption.bold())
                    .kerning(2)
                    .foregroundColor(.appAccent)
                Text("Nic nie wisi 🎉")
                    .font(.title2.bold())
                Text("Dodaj coś w zakładce Zadania — albo po prostu odpocznij. Odpoczynek to też zadanie.")
                    .font(.subheadline)
                    .foregroundColor(.appMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x241B3F), Color.appCard],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22).stroke(Color(hex: 0x3B2D63))
        )
        .shadow(color: Color.appAccentDark.opacity(0.35), radius: 18, x: 0, y: 8)
    }

    /// Powrót po przerwie bez ani jednego wyrzutu sumienia. Moment, w którym
    /// inne apki witają stertą zaległości — i w którym ADHD-owcy je kasują.
    private var welcomeBackCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dobrze Cię widzieć 💜")
                .font(.headline)
            Text("Nie było Cię \(store.daysAway) dni — i nic się nie stało. Nic nie przepadło, nic Cię nie goni, żadnych zaległości. Po prostu wybierz jedną małą rzecz.")
                .font(.subheadline)
                .foregroundColor(.appMuted)
            Button {
                store.dismissWelcomeBack()
            } label: {
                Text("Jasne, zaczynamy")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.appCard2, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appAccent.opacity(0.5)))
        .transition(.scale.combined(with: .opacity))
    }

    private func ghostButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.appCard2, in: RoundedRectangle(cornerRadius: 14))
                .foregroundColor(.white)
        }
    }

    @ViewBuilder
    private var doneTodaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("DZISIAJ OGARNIĘTE")
                    .font(.caption.bold())
                    .kerning(1.2)
                    .foregroundColor(.appMuted)
                Spacer()
                dailyGoalBadge
            }

            if store.doneToday.isEmpty {
                Text("Jeszcze nic — i to jest OK. Zacznij od jednej małej rzeczy. 💜")
                    .font(.subheadline)
                    .foregroundColor(.appMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(store.doneToday) { task in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.appGood)
                        Text(task.title)
                            .strikethrough()
                            .foregroundColor(.appMuted)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.appCard, in: RoundedRectangle(cornerRadius: 14))
                }
            }

            Button {
                showLogDone = true
            } label: {
                Text("+ Zrobiłem coś spoza listy")
                    .font(.footnote.bold())
                    .foregroundColor(.appMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.appCard.opacity(0.6),
                                in: RoundedRectangle(cornerRadius: 12))
            }
            .alert("Co takiego ogarnąłeś?", isPresented: $showLogDone) {
                TextField("np. zadzwoniłem do przychodni", text: $doneText)
                Button("Zalicz to ✓") {
                    store.logDoneOutsideList(doneText)
                    doneText = ""
                }
                Button("Anuluj", role: .cancel) { doneText = "" }
            } message: {
                Text("Nie było na liście, a i tak się liczy. Serio.")
            }
        }
    }

    /// Cel dnia: 3 zadania. Mały, osiągalny — reszta to bonus.
    @ViewBuilder
    private var dailyGoalBadge: some View {
        let count = store.doneToday.count
        if count >= 3 {
            Text("🏆 Cel dnia!")
                .font(.caption.bold())
                .foregroundColor(.appWarn)
        } else {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(Color.appCard2, lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: CGFloat(count) / 3)
                        .stroke(Color.appAccent,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 18, height: 18)
                .animation(.spring(duration: 0.5), value: count)
                Text("\(count)/3")
                    .font(.caption.bold())
                    .foregroundColor(.appMuted)
            }
            .accessibilityLabel("Cel dnia: \(count) z 3 zadań")
        }
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("📈 Twój tydzień")
            Chart(store.weekStats) { stat in
                BarMark(
                    x: .value("Dzień", stat.label),
                    y: .value("Zadania", stat.count)
                )
                .cornerRadius(5)
                .foregroundStyle(stat.isToday ? Color.appAccent : Color.appAccent.opacity(0.35))
            }
            .frame(height: 110)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.appMuted)
                }
            }
        }
        .padding(16)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appLine))
    }
}
