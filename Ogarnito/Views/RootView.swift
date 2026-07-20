import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: AppStore

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
            }
            .tint(.appAccent)
        }
        .background(Color.appBg)
        .overlay(alignment: .top) { PraiseBanner() }
        .overlay(ConfettiOverlay(trigger: store.confettiBurst))
    }
}

struct XPHeader: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        HStack(alignment: .center) {
            (Text("⚡ Ogarni") + Text("to").foregroundColor(.appAccent))
                .font(.title2.bold())
            Spacer()
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
