import SwiftUI
import UIKit

/// Timer skupienia: umowa z mózgiem — pracujesz TYLKO tyle, potem możesz przestać.
/// (Spoiler: często nie chcesz.)
struct FocusTimerView: View {
    @EnvironmentObject var store: AppStore
    @State private var totalSeconds = 15 * 60
    @State private var remaining = 15 * 60
    @State private var isRunning = false

    private let presets = [5, 15, 25]
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
        .background(Color.appBg)
        .onReceive(tick) { _ in
            guard isRunning else { return }
            remaining -= 1
            if remaining <= 0 { finish() }
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
        totalSeconds = minutes * 60
        remaining = totalSeconds
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func start() {
        if remaining <= 0 { remaining = totalSeconds }
        isRunning = true
        // Ekran nie gaśnie w trakcie sesji skupienia.
        UIApplication.shared.isIdleTimerDisabled = true
        Haptics.tap()
    }

    private func pause() {
        isRunning = false
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func finish() {
        isRunning = false
        remaining = 0
        UIApplication.shared.isIdleTimerDisabled = false
        store.reward(8, big: true)
    }

    private func reset() {
        isRunning = false
        remaining = totalSeconds
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
