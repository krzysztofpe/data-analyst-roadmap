import SwiftUI
import UIKit

/// Timer skupienia: umowa z mózgiem — pracujesz TYLKO tyle, potem możesz przestać.
/// (Spoiler: często nie chcesz.)
struct FocusTimerView: View {
    @EnvironmentObject var store: AppStore
    @State private var totalSeconds = 15 * 60
    @State private var remaining = 15 * 60
    @State private var isRunning = false
    /// Moment zakończenia sesji — odliczanie liczone od daty, żeby działało
    /// poprawnie także po zablokowaniu ekranu i powrocie do aplikacji.
    @State private var endDate: Date?

    private let presets = [2, 5, 15, 25]
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var progress: Double {
        1 - Double(remaining) / Double(totalSeconds)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("⏱️ Umowa z mózgiem: pracujesz TYLKO tyle. Potem możesz przestać. (Spoiler: często nie chcesz.)")
                    .font(.caption)
                    .foregroundColor(.appMuted)
                    .multilineTextAlignment(.center)

                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { minutes in
                        Button {
                            selectPreset(minutes)
                        } label: {
                            Text("\(minutes) min")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    totalSeconds == minutes * 60 ? Color.appAccentDark : Color.appCard2,
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                                .foregroundColor(.white)
                        }
                    }
                }

                ZStack {
                    Circle()
                        .stroke(Color.appCard2, lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.appAccent,
                                style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)
                    VStack(spacing: 4) {
                        Text(timeString)
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text(stateLabel)
                            .font(.caption)
                            .foregroundColor(.appMuted)
                    }
                }
                .frame(width: 230, height: 230)
                .padding(.vertical, 6)

                HStack(spacing: 10) {
                    Button {
                        isRunning ? pause() : start()
                    } label: {
                        Text(isRunning ? "Pauza" : "Start")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.appAccentDark, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundColor(.white)
                    }
                    Button {
                        reset()
                    } label: {
                        Text("Reset")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.appCard2, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: 300)
            }
            .padding(16)
        }
        .background(AppBackground())
        .buttonStyle(ScaleButtonStyle())
        .onReceive(tick) { _ in
            guard isRunning, let end = endDate else { return }
            remaining = max(0, Int(end.timeIntervalSinceNow.rounded()))
            if remaining <= 0 { finish() }
        }
        .onChange(of: store.timerRequest) {
            // Inne widoki (np. „Nie mogę zacząć") mogą poprosić o start z zadanym czasem.
            guard let minutes = store.timerRequest else { return }
            selectPreset(minutes)
            start()
            store.timerRequest = nil
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private var timeString: String {
        String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    private var stateLabel: String {
        if isRunning { return "lecimy!" }
        return remaining == totalSeconds ? "gotowy" : "pauza"
    }

    private func selectPreset(_ minutes: Int) {
        isRunning = false
        endDate = nil
        totalSeconds = minutes * 60
        remaining = totalSeconds
        UIApplication.shared.isIdleTimerDisabled = false
        FocusNotifications.cancel()
    }

    private func start() {
        if remaining <= 0 { remaining = totalSeconds }
        endDate = Date().addingTimeInterval(TimeInterval(remaining))
        isRunning = true
        // Ekran nie gaśnie w trakcie sesji skupienia.
        UIApplication.shared.isIdleTimerDisabled = true
        FocusNotifications.schedule(after: TimeInterval(remaining))
        Haptics.tap()
    }

    private func pause() {
        isRunning = false
        endDate = nil
        UIApplication.shared.isIdleTimerDisabled = false
        FocusNotifications.cancel()
    }

    private func finish() {
        isRunning = false
        endDate = nil
        remaining = 0
        UIApplication.shared.isIdleTimerDisabled = false
        FocusNotifications.cancel()
        store.reward(8, big: true)
    }

    private func reset() {
        isRunning = false
        endDate = nil
        remaining = totalSeconds
        UIApplication.shared.isIdleTimerDisabled = false
        FocusNotifications.cancel()
    }
}
