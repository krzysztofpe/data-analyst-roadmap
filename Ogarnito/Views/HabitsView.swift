import SwiftUI

/// Nawyki: siatka ostatnich 7 dni + streak. Nie przerywaj łańcucha —
/// a jak przerwiesz, wracasz następnego dnia bez dramatu.
struct HabitsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingAdd = false
    @State private var newHabitName = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if store.habits.isEmpty {
                    VStack(spacing: 8) {
                        Text("🌱").font(.system(size: 40))
                        Text("Zacznij od JEDNEGO nawyku.\nMałego. Śmiesznie małego.\n\nJeden pominięty dzień nic nie zepsuje — masz ❄️ dzień łaski.")
                            .font(.subheadline)
                            .foregroundColor(.appMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 30)
                } else {
                    ForEach(store.habits) { habit in
                        HabitCard(habit: habit)
                    }
                }

                Button {
                    showingAdd = true
                } label: {
                    Text("+ Nowy nawyk")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appCard2, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundColor(.white)
                }

                Text("🔥 Jeden pominięty dzień nie zeruje streaka — dostajesz ❄️ dzień łaski. Porażka to dopiero rzucenie tego w cholerę, a nie jedna wpadka.")
                    .font(.caption)
                    .foregroundColor(.appMuted)
            }
            .padding(16)
        }
        .background(AppBackground())
        .alert("Nowy nawyk", isPresented: $showingAdd) {
            TextField("np. Szklanka wody rano", text: $newHabitName)
            Button("Dodaj") {
                store.addHabit(newHabitName)
                newHabitName = ""
            }
            Button("Anuluj", role: .cancel) { newHabitName = "" }
        } message: {
            Text("Mały nawyk = taki, którego nie da się nie zrobić.")
        }
    }
}

struct HabitCard: View {
    @EnvironmentObject var store: AppStore
    let habit: Habit
    @State private var confirmDelete = false

    private var last7Days: [Date] {
        let cal = Calendar.current
        return (0..<7).reversed().compactMap {
            cal.date(byAdding: .day, value: -$0, to: Date())
        }
    }

    var body: some View {
        let info = store.streakInfo(for: habit)
        return VStack(spacing: 10) {
            HStack {
                Text(habit.name)
                    .font(.headline)
                Spacer()
                if info.graceDay != nil {
                    Text("❄️")
                        .font(.caption)
                        .accessibilityLabel("Dzień łaski użyty")
                }
                Text(info.count > 0 ? "🔥 \(info.count)" : "—")
                    .font(.subheadline.bold())
                    .foregroundColor(.appWarn)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.4), value: info.count)
                Button {
                    confirmDelete = true
                } label: {
                    Image(systemName: "trash")
                        .font(.footnote)
                        .frame(width: 30, height: 30)
                        .background(Color.appCard2, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.appMuted)
                }
                .accessibilityLabel("Usuń nawyk")
                .confirmationDialog(
                    "Usunąć nawyk „\(habit.name)” razem z całą historią?",
                    isPresented: $confirmDelete,
                    titleVisibility: .visible
                ) {
                    Button("Usuń", role: .destructive) { store.deleteHabit(habit.id) }
                    Button("Anuluj", role: .cancel) {}
                }
            }

            HStack(spacing: 6) {
                ForEach(last7Days, id: \.self) { day in
                    let key = Dates.dayKey(day)
                    let isToday = key == Dates.dayKey()
                    let hit = habit.doneDays.contains(key)
                    let weekday = Calendar.current.component(.weekday, from: day) - 1

                    VStack(spacing: 4) {
                        Text(Dates.shortWeekdays[weekday])
                            .font(.caption2)
                            .foregroundColor(.appMuted)
                        Button {
                            if isToday { store.toggleHabitToday(habit.id) }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(hit ? Color.appGood : Color.appCard2)
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isToday ? Color.appAccent : Color.appLine)
                                if hit {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundColor(Color(hex: 0x06281C))
                                        .transition(.scale.combined(with: .opacity))
                                } else if key == info.graceDay {
                                    Text("❄️").font(.caption2)
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: hit)
                        }
                        .buttonStyle(.plain)
                        .disabled(!isToday)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appLine))
    }
}
