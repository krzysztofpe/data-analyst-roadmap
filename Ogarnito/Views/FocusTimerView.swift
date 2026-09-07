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
                if let task = store.focusTask, !task.done {
                    VStack(spacing: 4) {
                        Text("SKUPIASZ SIĘ NA")
                            .font(.caption2.bold())
                            .kerning(1.5)
                            .foregroundColor(.appAccent)
                        Text(task.title)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        if task.focusTime > 0 {
                            Text("dotąd: \(TimeText.minutes(task.focusTime))")
                                .font(.caption)
                                .foregroundColor(.appMuted)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.appCard, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appLine))
                } else {
                    Text("⏱️ Umowa z mózgiem: pracujesz TYLKO tyle. Potem możesz przestać. (Spoiler: często nie chcesz.)")
                        .font(.caption)
                        .foregroundColor(.appMuted)
                        .multilineTextAlignment(.center)
                }

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
                            .contentTransition(.numericText(countsDown: true))
                            .animation(.linear(duration: 0.3), value: remaining)
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
                            .background(
                                LinearGradient(colors: [.appAccentDark, Color(hex: 0x9333EA)],
                                               startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
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

                if store.focusToday > 0 {
                    Text("Dziś w skupieniu: \(TimeText.minutes(store.focusToday))")
                        .font(.footnote.bold())
                        .foregroundColor(.appGood)
                        .padding(.top, 4)
                }
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
        .onChange(of: store.timerRequest) { consumeTimerRequest() }
        // Zakładka timera powstaje dopiero przy pierwszym wejściu, więc samo
        // onChange przegapiłoby prośbę wysłaną z innego widoku.
        .onAppear { consumeTimerRequest() }
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

    /// Inne widoki (np. „Nie mogę zacząć") proszą o start z zadanym czasem.
    private func consumeTimerRequest() {
        guard let minutes = store.timerRequest else { return }
        selectPreset(minutes)
        start()
        store.timerRequest = nil
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
        store.logFocus(minutes: totalSeconds / 60)
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
