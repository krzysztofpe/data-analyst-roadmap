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
                        Text("Zacznij od JEDNEGO nawyku.\nMałego. Śmiesznie małego.")
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

                Text("🔥 Nie przerywaj łańcucha! A jak przerwiesz — trudno, wracasz następnego dnia. Jeden pominięty dzień to nie porażka.")
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

    private static let weekdaySymbols = ["nd", "pn", "wt", "śr", "cz", "pt", "sb"]

    private var last7Days: [Date] {
        let cal = Calendar.current
        return (0..<7).reversed().compactMap {
            cal.date(byAdding: .day, value: -$0, to: Date())
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(habit.name)
                    .font(.headline)
                Spacer()
                let streak = store.streak(for: habit)
                Text(streak > 0 ? "🔥 \(streak)" : "—")
                    .font(.subheadline.bold())
                    .foregroundColor(.appWarn)
                Button {
                    store.deleteHabit(habit.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.footnote)
                        .frame(width: 30, height: 30)
                        .background(Color.appCard2, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.appMuted)
                }
            }

            HStack(spacing: 6) {
                ForEach(last7Days, id: \.self) { day in
                    let key = Dates.dayKey(day)
                    let isToday = key == Dates.dayKey()
                    let hit = habit.doneDays.contains(key)
                    let weekday = Calendar.current.component(.weekday, from: day) - 1

                    VStack(spacing: 4) {
                        Text(Self.weekdaySymbols[weekday])
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
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
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
