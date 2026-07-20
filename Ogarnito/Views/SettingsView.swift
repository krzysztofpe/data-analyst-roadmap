import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("onboardingSeen") private var onboardingSeen = false
    @State private var confirmWipe = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text("Ustawienia")
                            .font(.title2.bold())
                        Spacer()
                        Button("Gotowe") { dismiss() }
                            .font(.headline)
                            .foregroundColor(.appAccent)
                    }
                    .padding(.top, 8)

                    statsCard
                    aboutCard
                    dangerCard

                    Text("Ogarnito \(appVersion) · zrobione z 💜 dla ADHD-mózgów")
                        .font(.caption2)
                        .foregroundColor(.appMuted)
                        .padding(.top, 4)
                }
                .padding(16)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .preferredColorScheme(.dark)
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("📊 Twoje postępy")
            statRow("Poziom", "\(store.level)")
            statRow("Punkty XP", "\(store.xp)")
            statRow("Zadania zrobione", "\(store.tasks.filter(\.done).count)")
            statRow("Aktywne nawyki", "\(store.habits.count)")
            HStack {
                Text("Zaoszczędzone na impulsach")
                    .foregroundColor(.appMuted)
                Spacer()
                Text(store.savedTotal, format: .currency(code: "PLN"))
                    .bold()
                    .foregroundColor(.appGood)
            }
            .font(.subheadline)
        }
        .padding(16)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appLine))
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.appMuted)
            Spacer()
            Text(value).bold()
        }
        .font(.subheadline)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("ℹ️ Aplikacja")

            Button {
                dismiss()
                // Odczekaj, aż arkusz się schowa, zanim wskoczy pełnoekranowe intro.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onboardingSeen = false
                }
            } label: {
                HStack {
                    Text("👋 Pokaż wprowadzenie ponownie")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.appMuted)
                }
                .font(.subheadline.bold())
                .foregroundColor(.white)
            }

            Divider().overlay(Color.appLine)

            HStack(alignment: .top, spacing: 10) {
                Text("🔒")
                Text("Twoje dane zostają na tym telefonie. Zero kont, zero chmury, zero śledzenia.")
                    .font(.caption)
                    .foregroundColor(.appMuted)
            }
        }
        .padding(16)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appLine))
    }

    private var dangerCard: some View {
        Button {
            confirmWipe = true
        } label: {
            Text("🗑️ Wymaż wszystkie dane")
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: 0x3B1D2A), in: RoundedRectangle(cornerRadius: 14))
                .foregroundColor(Color(hex: 0xF87171))
        }
        .confirmationDialog(
            "Na pewno? Znikną wszystkie zadania, nawyki, streaki i XP. Tego nie da się cofnąć.",
            isPresented: $confirmWipe,
            titleVisibility: .visible
        ) {
            Button("Wymaż wszystko", role: .destructive) {
                store.resetAll()
                dismiss()
            }
            Button("Anuluj", role: .cancel) {}
        }
    }
}
