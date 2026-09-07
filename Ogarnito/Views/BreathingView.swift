import SwiftUI

/// Pełnoekranowy tryb ratunkowy na stres i przytłoczenie:
/// oddech pudełkowy 4-4-4-4 albo uziemienie 5-4-3-2-1.
struct BreathingView: View {
    @EnvironmentObject var store: AppStore
    @State private var mode: Mode = .breath
    @State private var phaseLabel = "Przygotuj się…"
    @State private var scale: CGFloat = 0.55
    @State private var cycles = 0

    enum Mode: String, CaseIterable, Identifiable {
        case breath = "Oddech 4-4-4-4"
        case grounding = "5-4-3-2-1"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x1B1230), Color(hex: 0x0B0B14)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Picker("Tryb", selection: $mode) {
                    ForEach(Mode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 32)
                .padding(.top, 8)

                Spacer()

                if mode == .breath {
                    breathContent
                } else {
                    groundingContent
                }

                Spacer()

                Button {
                    store.finishBreathing(cycles: cycles)
                } label: {
                    Text("Zakończ")
                        .font(.headline)
                        .frame(maxWidth: 240)
                        .padding(.vertical, 14)
                        .background(Color.appCard2, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundColor(.white)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Oddech pudełkowy

    private var breathContent: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [Color.appAccent.opacity(0.55),
                                                Color.appAccentDark.opacity(0.25)],
                                       center: .center, startRadius: 10, endRadius: 150)
                    )
                    .scaleEffect(scale)
                Circle()
                    .stroke(Color.appAccent.opacity(0.5), lineWidth: 2)
                    .scaleEffect(scale)
                Text(phaseLabel)
                    .font(.title2.bold())
            }
            .frame(width: 270, height: 270)

            Text(cycles > 0 ? "Cykle: \(cycles) 🌊" : "Oddychaj zgodnie z kołem")
                .font(.subheadline)
                .foregroundColor(.appMuted)
        }
        .task { await runBreathLoop() }
    }

    private func runBreathLoop() async {
        let phases: [(label: String, target: CGFloat, seconds: UInt64)] = [
            ("Wdech…", 1.0, 4),
            ("Zatrzymaj", 1.0, 4),
            ("Wydech…", 0.55, 4),
            ("Zatrzymaj", 0.55, 4)
        ]
        while !Task.isCancelled {
            for phase in phases {
                phaseLabel = phase.label
                withAnimation(.easeInOut(duration: Double(phase.seconds))) {
                    scale = phase.target
                }
                try? await Task.sleep(nanoseconds: phase.seconds * 1_000_000_000)
                if Task.isCancelled { return }
            }
            cycles += 1
            Haptics.tap()
        }
    }

    // MARK: - Uziemienie 5-4-3-2-1

    private var groundingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wróć do teraz. Znajdź wokół siebie:")
                .font(.subheadline)
                .foregroundColor(.appMuted)

            groundingRow("👀", "5 rzeczy, które widzisz")
            groundingRow("✋", "4 rzeczy, których możesz dotknąć")
            groundingRow("👂", "3 dźwięki, które słyszysz")
            groundingRow("👃", "2 zapachy")
            groundingRow("👅", "1 smak")

            Text("Powoli. Nazwij każdą rzecz w myślach.")
                .font(.caption)
                .foregroundColor(.appMuted)
                .padding(.top, 4)
        }
        .padding(.horizontal, 32)
    }

    private func groundingRow(_ emoji: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Text(emoji).font(.title3)
            Text(text).font(.body.bold())
            Spacer()
        }
        .padding(14)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appLine))
    }
}
