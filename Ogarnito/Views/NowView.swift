import SwiftUI

/// Widok „Teraz" — pokazuje JEDNO zadanie i tylko jego następny krok,
/// żeby nie przytłaczać. Serce aplikacji.
struct NowView: View {
    @EnvironmentObject var store: AppStore
    @State private var showStuck = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                nowCard
                doneTodaySection
            }
            .padding(16)
        }
        .background(AppBackground())
        .buttonStyle(ScaleButtonStyle())
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
                    Button {
                        store.selectedTab = .tasks
                    } label: {
                        Text("🔪 Rozbij")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.appCard2, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundColor(.white)
                    }
                    Button {
                        store.selectedTab = .timer
                    } label: {
                        Text("⏱️ Skup się")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.appCard2, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundColor(.white)
                    }
                }
                .font(.subheadline.bold())

                Button {
                    showStuck = true
                } label: {
                    Text("😩 Nie mogę zacząć")
                        .font(.footnote.bold())
                        .foregroundColor(.appMuted)
                        .padding(.top, 2)
                }
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

    @ViewBuilder
    private var doneTodaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DZISIAJ OGARNIĘTE")
                .font(.caption.bold())
                .kerning(1.2)
                .foregroundColor(.appMuted)

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
        }
    }
}
