import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("onboardingSeen") private var onboardingSeen = false

    var body: some View {
        VStack(spacing: 0) {
            XPHeader()
            TabView(selection: $store.selectedTab) {
                NowView()
                    .tabItem { Label("Teraz", systemImage: "target") }
                    .tag(AppStore.Tab.now)
                TasksView()
                    .tabItem { Label("Zadania", systemImage: "checklist") }
                    .tag(AppStore.Tab.tasks)
                HabitsView()
                    .tabItem { Label("Nawyki", systemImage: "flame.fill") }
                    .tag(AppStore.Tab.habits)
                FocusTimerView()
                    .tabItem { Label("Timer", systemImage: "timer") }
                    .tag(AppStore.Tab.timer)
                LifeView()
                    .tabItem { Label("Życie", systemImage: "heart.fill") }
                    .tag(AppStore.Tab.life)
            }
            .tint(.appAccent)
            // Onboarding na osobnym widoku niż cover oddechu — dwa fullScreenCover
            // na tym samym widoku nie działają razem.
            .fullScreenCover(isPresented: Binding(
                get: { !onboardingSeen },
                set: { presented in if !presented { onboardingSeen = true } }
            )) {
                OnboardingView()
            }
        }
        .background(Color.appBg)
        .overlay(alignment: .top) { PraiseBanner() }
        .overlay(ConfettiOverlay(trigger: store.confettiBurst))
        .fullScreenCover(isPresented: $store.showBreathing) {
            BreathingView()
        }
    }
}

struct XPHeader: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            (Text("⚡ Ogarni") + Text("to").foregroundColor(.appAccent))
                .font(.title2.bold())
            Spacer()
            // Szybki dostęp do oddechu ratunkowego z każdego miejsca w apce.
            Button {
                store.showBreathing = true
            } label: {
                Text("🌬️")
                    .font(.title3)
                    .frame(width: 38, height: 38)
                    .background(Color.appCard2, in: Circle())
                    .overlay(Circle().stroke(Color.appLine))
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Oddech ratunkowy")
            VStack(alignment: .trailing, spacing: 4) {
                Text("Poziom \(store.level) · \(store.xp) XP")
                    .font(.caption)
                    .foregroundColor(.appMuted)
                ProgressView(value: store.levelProgress)
                    .tint(.appAccent)
                    .frame(width: 110)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.appBg)
    }
}

struct PraiseBanner: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ZStack {
            if let praise = store.praise {
                Text(praise)
                    .font(.subheadline.bold())
                    .foregroundColor(.appGood)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.appCard2, in: Capsule())
                    .overlay(Capsule().stroke(Color.appLine))
                    .padding(.top, 52)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: store.praise)
    }
}

struct ConfettiOverlay: View {
    let trigger: Int
    @State private var particles: [Particle] = []

    struct Particle: Identifiable {
        let id = UUID()
        let emoji: String
        let x: CGFloat
        let delay: Double
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    FallingEmoji(particle: p, height: geo.size.height)
                        .position(x: p.x * geo.size.width, y: geo.size.height * 0.15)
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onChange(of: trigger) {
            spawn()
        }
    }

    private func spawn() {
        let emojis = ["🎉", "✨", "⭐", "💜", "🎊", "💥"]
        let batch = (0..<18).map { _ in
            Particle(
                emoji: emojis.randomElement()!,
                x: CGFloat.random(in: 0.05...0.95),
                delay: Double.random(in: 0...0.3)
            )
        }
        particles.append(contentsOf: batch)
        let ids = Set(batch.map(\.id))
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            particles.removeAll { ids.contains($0.id) }
        }
    }
}

private struct FallingEmoji: View {
    let particle: ConfettiOverlay.Particle
    let height: CGFloat
    @State private var flying = false

    var body: some View {
        Text(particle.emoji)
            .font(.system(size: 24))
            .offset(y: flying ? height * 0.5 : 0)
            .rotationEffect(.degrees(flying ? 240 : 0))
            .opacity(flying ? 0 : 1)
            .onAppear {
                withAnimation(.easeIn(duration: 1.2).delay(particle.delay)) {
                    flying = true
                }
            }
    }
}

#Preview {
    RootView()
        .environmentObject(AppStore())
        .preferredColorScheme(.dark)
}
