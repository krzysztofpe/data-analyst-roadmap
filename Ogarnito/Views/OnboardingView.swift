import SwiftUI

/// Krótki onboarding przy pierwszym uruchomieniu — 4 karty, zero ściany tekstu.
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private let pages: [(emoji: String, title: String, text: String)] = [
        ("🧠", "Zrzuć wszystko z głowy",
         "Wpisujesz albo mówisz: „Hej Siri, dodaj zadanie do Ogarnito”. Głowa jest od wymyślania, nie od pamiętania."),
        ("🎯", "Jedno zadanie naraz",
         "Żadnych przytłaczających list. Widzisz tylko następny mały krok — i go robisz."),
        ("💜", "Życie też się liczy",
         "Jedzenie, woda, oddech na stres i 48-godzinna poczekalnia na impulsywne zakupy."),
        ("✨", "Dopamina wbudowana",
         "XP, poziomy, konfetti i streaki. Twój mózg lubi nagrody — będą.")
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x1B1230), Color(hex: 0x0B0B14)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 18) {
                            Text(pages[i].emoji)
                                .font(.system(size: 76))
                            Text(pages[i].title)
                                .font(.title.bold())
                                .multilineTextAlignment(.center)
                            Text(pages[i].text)
                                .font(.body)
                                .foregroundColor(.appMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        dismiss()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Dalej" : "Zaczynamy ⚡")
                        .font(.headline)
                        .frame(maxWidth: 280)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(colors: [.appAccentDark, Color(hex: 0x9333EA)],
                                           startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .foregroundColor(.white)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.bottom, 28)
            }
            .padding(.top, 24)
        }
        .preferredColorScheme(.dark)
    }
}
