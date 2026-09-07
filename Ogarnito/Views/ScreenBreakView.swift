import SwiftUI

/// Przerwanie pętli scrollowania. Bezmyślne przewijanie prawie nigdy nie jest
/// rozrywką — to regulacja emocji. Dlatego nie moralizujemy, tylko dajemy
/// oddech, pytamy o potrzebę pod spodem i podsuwamy konkretną alternatywę.
struct ScreenBreakView: View {
    @EnvironmentObject var store: AppStore
    @State private var step: Step = .pause
    @State private var secondsLeft = 20
    @State private var counted = false
    @State private var picked: Need?

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum Step { case pause, need }

    /// Potrzeba, która najczęściej siedzi pod scrollowaniem.
    struct Need: Identifiable, Equatable {
        let id: String
        let emoji: String
        let name: String
        let answer: String
        let action: String
    }

    private let needs = [
        Need(id: "nuda", emoji: "😐", name: "Nudzi mi się",
             answer: "Nuda przy ADHD boli fizycznie. Ale mikro-zadanie daje dopaminę, po której czujesz się lepiej, a nie gorzej.",
             action: "Daj mi coś malutkiego"),
        Need(id: "stres", emoji: "😰", name: "Jestem spięty",
             answer: "Scroll rozprasza napięcie, ale go nie rozładowuje. Oddech rozładowuje — w dosłownie minutę.",
             action: "Weź oddech"),
        Need(id: "zmeczenie", emoji: "😴", name: "Jestem wykończony",
             answer: "To nie lenistwo, tylko pusty bak. Telefon nie regeneruje — po godzinie scrolla będziesz bardziej zmęczony niż teraz.",
             action: "Odpocznij naprawdę"),
        Need(id: "unikanie", emoji: "🙈", name: "Coś odkładam",
             answer: "Scroll jest znieczuleniem na to jedno zadanie. Zobacz je — zwykle okazuje się mniejsze, niż urosło w głowie.",
             action: "Pokaż, co odkładam")
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x1B1230), Color(hex: 0x0B0B14)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                switch step {
                case .pause: pauseStep
                case .need:  needStep
                }
                Spacer()

                Button {
                    finish()
                } label: {
                    Text("Wróć do apki")
                        .font(.subheadline.bold())
                        .foregroundColor(.appMuted)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 28)
        }
        .buttonStyle(ScaleButtonStyle())
        .onReceive(tick) { _ in
            guard step == .pause, secondsLeft > 0 else { return }
            secondsLeft -= 1
            if secondsLeft == 0 {
                withAnimation(.spring(duration: 0.4)) { step = .need }
            }
        }
        .onAppear {
            // Samo przyłapanie się jest wygraną — nagradzamy je od razu,
            // niezależnie od tego, co użytkownik zrobi dalej.
            if !counted {
                counted = true
                store.catchScroll()
            }
        }
    }

    // MARK: - 1. Pauza

    private var pauseStep: some View {
        VStack(spacing: 18) {
            Text("🛑").font(.system(size: 66))
            Text("Przyłapałeś się")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("To jest ta trudna część — i właśnie ją zrobiłeś. Zatrzymaj się na chwilę, zanim zdecydujesz, co dalej.")
                .font(.body)
                .foregroundColor(.appMuted)
                .multilineTextAlignment(.center)

            ZStack {
                Circle().stroke(Color.appCard2, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(20 - secondsLeft) / 20)
                    .stroke(Color.appAccent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: secondsLeft)
                Text("\(secondsLeft)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
            }
            .frame(width: 146, height: 146)
            .padding(.top, 4)

            Button {
                withAnimation(.spring(duration: 0.4)) { step = .need }
            } label: {
                Text("Pomiń pauzę")
                    .font(.footnote.bold())
                    .foregroundColor(.appMuted)
            }
        }
    }

    // MARK: - 2. Potrzeba pod spodem

    @ViewBuilder
    private var needStep: some View {
        if let need = picked {
            VStack(spacing: 18) {
                Text(need.emoji).font(.system(size: 58))
                Text(need.name).font(.title3.bold())
                Text(need.answer)
                    .font(.body)
                    .foregroundColor(.appMuted)
                    .multilineTextAlignment(.center)

                Button {
                    perform(need)
                } label: {
                    Text(need.action)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(colors: [.appAccentDark, Color(hex: 0x9333EA)],
                                           startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .foregroundColor(.white)
                }
                .padding(.top, 6)

                Button {
                    withAnimation { picked = nil }
                } label: {
                    Text("To jednak coś innego")
                        .font(.footnote.bold())
                        .foregroundColor(.appMuted)
                }
            }
        } else {
            VStack(spacing: 14) {
                Text("Czego teraz naprawdę potrzebujesz?")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                Text(store.scrollCatchesToday > 1
                     ? "Dziś przerwane \(store.scrollCatchesToday)× — liczymy przyłapania, nie potknięcia."
                     : "Scroll rzadko jest odpowiedzią na to pytanie.")
                    .font(.caption)
                    .foregroundColor(.appMuted)
                    .multilineTextAlignment(.center)

                ForEach(needs) { need in
                    Button {
                        withAnimation(.spring(duration: 0.35)) { picked = need }
                    } label: {
                        HStack(spacing: 12) {
                            Text(need.emoji).font(.title3)
                            Text(need.name).font(.headline).foregroundColor(.white)
                            Spacer()
                        }
                        .padding(15)
                        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appLine))
                    }
                }
            }
        }
    }

    // MARK: - Akcje

    private func perform(_ need: Need) {
        switch need.id {
        case "nuda":
            store.currentEnergy = .low
            store.selectedTab = .now
            finish()
        case "stres":
            // Najpierw domykamy ten ekran, dopiero potem otwieramy oddech —
            // dwa pełnoekranowe widoki naraz gryzą się ze sobą.
            finish()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                store.showBreathing = true
            }
        case "zmeczenie":
            store.selectedTab = .life
            finish()
        default:
            store.selectedTab = .now
            finish()
        }
    }

    private func finish() { store.showScreenBreak = false }
}
