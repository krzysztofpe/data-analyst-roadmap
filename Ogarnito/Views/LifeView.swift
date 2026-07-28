import SwiftUI

/// „Życie" — jedzenie, stres i pieniądze: rzeczy, które ADHD-mózg
/// najczęściej gubi po drodze.
struct LifeView: View {
    @EnvironmentObject var store: AppStore
    @State private var itemName = ""
    @State private var itemPrice = ""

    private let meals: [(key: String, label: String)] = [
        ("sniadanie", "🍳 Śniadanie"),
        ("obiad", "🥘 Obiad"),
        ("kolacja", "🥪 Kolacja")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                mealsCard
                stressCard
                walletCard
            }
            .padding(16)
        }
        .background(AppBackground())
        .scrollDismissesKeyboard(.interactively)
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Jedzenie

    private var mealsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("🍽️ Jedzenie")
            Text("ADHD-mózg potrafi zapomnieć o jedzeniu. Odhacz posiłki — to też produktywność.")
                .font(.caption)
                .foregroundColor(.appMuted)

            HStack(spacing: 8) {
                ForEach(meals, id: \.key) { meal in
                    let done = store.todayCare.meals.contains(meal.key)
                    Button {
                        store.toggleMeal(meal.key)
                    } label: {
                        Text(meal.label)
                            .font(.footnote.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(done ? Color.appGood : Color.appCard2,
                                        in: RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(done ? Color(hex: 0x06281C) : .white)
                    }
                }
            }

            HStack {
                Text("💧 Woda: \(store.todayCare.water) szkl.")
                    .font(.subheadline.bold())
                Spacer()
                Button { store.changeWater(-1) } label: { stepperIcon("minus") }
                    .accessibilityLabel("Odejmij szklankę wody")
                Button { store.changeWater(1) } label: { stepperIcon("plus") }
                    .accessibilityLabel("Dodaj szklankę wody")
            }
        }
        .padding(16)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appLine))
    }

    private func stepperIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.subheadline.bold())
            .frame(width: 38, height: 38)
            .background(Color.appCard2, in: RoundedRectangle(cornerRadius: 11))
            .foregroundColor(.appAccent)
    }

    // MARK: - Stres

    private var stressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("😮‍💨 Stres i przytłoczenie")
            Text("Za dużo naraz? Minuta oddechu naprawdę robi robotę — obniża tętno i wyłącza alarm w głowie.")
                .font(.caption)
                .foregroundColor(.appMuted)

            Button {
                store.showBreathing = true
            } label: {
                Text("🌬️ Oddech ratunkowy")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [.appAccentDark, Color(hex: 0x9333EA)],
                                       startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appLine))
    }

    // MARK: - Portfel impulsów

    private var walletCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("💸 Portfel impulsów")
            Text("Chcesz coś kupić pod wpływem impulsu? Wrzuć to tutaj i odczekaj 48 godzin. Impuls mija — kasa zostaje.")
                .font(.caption)
                .foregroundColor(.appMuted)

            if store.savedTotal > 0 {
                (Text("✨ Zaoszczędzone: ")
                 + Text(store.savedTotal, format: .currency(code: Money.code)).bold())
                    .font(.subheadline)
                    .foregroundColor(.appGood)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.appGood.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 8) {
                TextField("Co chcesz kupić?", text: $itemName)
                    .submitLabel(.done)
                    .padding(11)
                    .background(Color.appCard2, in: RoundedRectangle(cornerRadius: 11))
                TextField("Cena", text: $itemPrice)
                    .keyboardType(.decimalPad)
                    .frame(width: 70)
                    .padding(11)
                    .background(Color.appCard2, in: RoundedRectangle(cornerRadius: 11))
                Button(action: addImpulse) {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                        .background(Color.appAccentDark, in: RoundedRectangle(cornerRadius: 11))
                        .foregroundColor(.white)
                }
                .accessibilityLabel("Dodaj do poczekalni zakupowej")
            }

            // Odświeżanie co minutę, żeby odliczanie i przyciski decyzji
            // pojawiały się bez ponownego otwierania widoku.
            TimelineView(.everyMinute) { _ in
                VStack(spacing: 8) {
                    ForEach(store.pendingImpulses) { item in
                        ImpulseRow(item: item)
                    }
                }
            }

            if !store.decidedImpulses.isEmpty {
                SectionTitle("Historia")
                ForEach(store.decidedImpulses.prefix(5)) { item in
                    HStack(spacing: 8) {
                        Text(item.decision == .skipped ? "💸" : "🛍️")
                        Text(item.name)
                            .font(.footnote)
                            .strikethrough(item.decision == .skipped)
                            .foregroundColor(.appMuted)
                        Spacer()
                        Text(item.price, format: .currency(code: Money.code))
                            .font(.footnote.bold())
                            .foregroundColor(item.decision == .skipped ? .appGood : .appMuted)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appLine))
    }

    private func addImpulse() {
        let price = Double(itemPrice.replacingOccurrences(of: ",", with: ".")) ?? 0
        store.addImpulse(name: itemName, price: price)
        itemName = ""
        itemPrice = ""
    }
}

struct ImpulseRow: View {
    @EnvironmentObject var store: AppStore
    let item: ImpulseItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.subheadline.bold())
                Spacer()
                Text(item.price, format: .currency(code: Money.code))
                    .font(.subheadline)
                    .foregroundColor(.appMuted)
            }

            if item.isReady {
                HStack(spacing: 8) {
                    Button {
                        store.decideImpulse(item.id, skipped: true)
                    } label: {
                        Text("Odpuszczam 💸")
                            .font(.footnote.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.appGood, in: RoundedRectangle(cornerRadius: 10))
                            .foregroundColor(Color(hex: 0x06281C))
                    }
                    Button {
                        store.decideImpulse(item.id, skipped: false)
                    } label: {
                        Text("Kupuję 🛍️")
                            .font(.footnote.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.appCard2, in: RoundedRectangle(cornerRadius: 10))
                            .foregroundColor(.white)
                    }
                }
                Text("48 h minęło — nadal tego chcesz, czy to był impuls?")
                    .font(.caption2)
                    .foregroundColor(.appMuted)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "hourglass")
                        .font(.caption)
                    Text(remainingText)
                        .font(.caption)
                }
                .foregroundColor(.appWarn)
            }
        }
        .padding(12)
        .background(Color.appCard2.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appLine))
    }

    private var remainingText: String {
        let secs = item.readyAt.timeIntervalSinceNow
        let hours = Int((secs / 3600).rounded(.up))
        if hours >= 2 { return "czekasz jeszcze \(hours) h" }
        let minutes = max(1, Int((secs / 60).rounded(.up)))
        return "czekasz jeszcze \(minutes) min"
    }
}
