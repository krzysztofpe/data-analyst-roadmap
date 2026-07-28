import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("onboardingSeen") private var onboardingSeen = false
    @State private var confirmWipe = false

    // Przypomnienia: włączniki + godziny (sekundy od północy).
    @AppStorage("rem.morning.on") private var morningOn = false
    @AppStorage("rem.morning.time") private var morningTime: Double = 9 * 3600
    @AppStorage("rem.meal.on") private var mealOn = false
    @AppStorage("rem.meal.time") private var mealTime: Double = 13 * 3600
    @AppStorage("rem.evening.on") private var eveningOn = false
    @AppStorage("rem.evening.time") private var eveningTime: Double = 20 * 3600

    // Kopia zapasowa.
    @State private var backupURL: URL?
    @State private var showImporter = false
    @State private var pendingImport: Data?
    @State private var importFailed = false

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
                    remindersCard
                    backupCard
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
        .onAppear { backupURL = store.writeBackupFile() }
        .fileImporter(isPresented: $showImporter,
                      allowedContentTypes: [.json]) { result in
            guard case .success(let url) = result else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            if let data = try? Data(contentsOf: url) {
                pendingImport = data
            } else {
                importFailed = true
            }
        }
        .confirmationDialog(
            "Zastąpić obecne dane tą kopią? Obecny stan aplikacji zostanie nadpisany.",
            isPresented: Binding(
                get: { pendingImport != nil },
                set: { if !$0 { pendingImport = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Przywróć z kopii", role: .destructive) {
                if let data = pendingImport, store.importBackup(data) {
                    dismiss()
                } else {
                    importFailed = true
                }
                pendingImport = nil
            }
            Button("Anuluj", role: .cancel) { pendingImport = nil }
        }
        .alert("Nie udało się wczytać pliku", isPresented: $importFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Upewnij się, że to kopia zapasowa z Ogarnito (plik .json).")
        }
    }

    // MARK: - Przypomnienia

    private var remindersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("🔔 Przypomnienia")
            Text("Zewnętrzna pamięć: telefon przypomni, bo ADHD-mózg nie przypomni.")
                .font(.caption)
                .foregroundColor(.appMuted)

            reminderRow("☀️ Zaplanuj dzień", kind: .morning,
                        isOn: $morningOn, time: $morningTime)
            reminderRow("🍽️ Zjedz coś", kind: .meal,
                        isOn: $mealOn, time: $mealTime)
            reminderRow("🌙 Domknij dzień", kind: .evening,
                        isOn: $eveningOn, time: $eveningTime)
        }
        .padding(16)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appLine))
    }

    private func reminderRow(_ label: String, kind: DailyReminder,
                             isOn: Binding<Bool>, time: Binding<Double>) -> some View {
        HStack {
            Toggle(label, isOn: Binding(
                get: { isOn.wrappedValue },
                set: { on in
                    isOn.wrappedValue = on
                    if on {
                        kind.schedule(secondsFromMidnight: time.wrappedValue)
                    } else {
                        kind.cancel()
                    }
                }
            ))
            .font(.subheadline.bold())
            .tint(.appAccent)

            if isOn.wrappedValue {
                DatePicker("", selection: Binding(
                    get: {
                        Calendar.current.startOfDay(for: Date())
                            .addingTimeInterval(time.wrappedValue)
                    },
                    set: { date in
                        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                        time.wrappedValue = Double((c.hour ?? 0) * 3600 + (c.minute ?? 0) * 60)
                        kind.schedule(secondsFromMidnight: time.wrappedValue)
                    }
                ), displayedComponents: .hourAndMinute)
                .labelsHidden()
                .frame(width: 90)
            }
        }
    }

    // MARK: - Kopia zapasowa

    private var backupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("💾 Kopia zapasowa")
            Text("Wszystko trzymasz lokalnie — zrób od czasu do czasu kopię, np. do Plików albo na maila do siebie.")
                .font(.caption)
                .foregroundColor(.appMuted)

            if let url = backupURL {
                ShareLink(item: url) {
                    HStack {
                        Text("📤 Eksportuj dane (JSON)")
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                            .foregroundColor(.appMuted)
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                }
            }

            Divider().overlay(Color.appLine)

            Button {
                showImporter = true
            } label: {
                HStack {
                    Text("📥 Przywróć z kopii")
                    Spacer()
                    Image(systemName: "square.and.arrow.down")
                        .font(.caption)
                        .foregroundColor(.appMuted)
                }
                .font(.subheadline.bold())
                .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appLine))
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
                Text(store.savedTotal, format: .currency(code: Money.code))
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
                Text("🎙️")
                Text("Powiedz „Hej Siri, dodaj zadanie do Ogarnito”, a myśl trafi na listę bez odblokowywania telefonu.")
                    .font(.caption)
                    .foregroundColor(.appMuted)
            }

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
