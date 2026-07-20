# ⚡ Ogarnito — natywna aplikacja iOS dla ADHD-owców

Planer zadań i nawyków napisany w **Swift / SwiftUI**: buduj nawyki i *get shit done* —
bez przytłaczających list, za to z dopaminą.

## Funkcje

- **🎯 Teraz** — pokazuje **jedno** zadanie naraz (i tylko jego następny krok), żeby nie
  przytłaczać. Tryb „🐸 zjedz żabę": oznacz najważniejszą rzecz dnia.
- **📝 Zadania + brain dump** — wrzucasz wszystko z głowy bez planowania i oceniania.
  Każde zadanie rozbijesz na mikro-kroki (max 10 minut każdy).
- **🔥 Nawyki** — siatka ostatnich 7 dni i licznik streaka. Nie przerywaj łańcucha —
  a jak przerwiesz, wracasz następnego dnia, bez dramatu.
- **⏱️ Timer skupienia** — 2/5/15/25 minut. Umowa z mózgiem: pracujesz *tylko tyle*,
  potem możesz przestać. Ekran nie gaśnie w trakcie sesji.
- **😩 „Nie mogę zacząć"** — odblokowanie prokrastynacji: 2 minuty byle jak,
  śmiesznie mały krok albo najpierw wydech.
- **🍽️ Jedzenie i woda** — ADHD-mózg zapomina jeść. Odhaczasz posiłki i szklanki
  wody w zakładce „Życie" (też nagradzane XP).
- **💸 Portfel impulsów** — chcesz coś kupić pod wpływem impulsu? Wrzucasz do
  poczekalni na 48 h. Po odczekaniu decydujesz: kupujesz albo odpuszczasz —
  apka sumuje zaoszczędzone pieniądze.
- **🌬️ Oddech ratunkowy** — pełnoekranowy oddech pudełkowy 4-4-4-4 z animowanym
  kołem oraz uziemienie 5-4-3-2-1 na stres i przytłoczenie. Dostępny jednym
  tapnięciem z nagłówka w każdym miejscu aplikacji.
- **✨ Dopamina** — XP, poziomy, konfetti, haptyka i pochwały po każdym zrobionym kroku.
- **🏆 Cel dnia: 3 zadania** — mały, osiągalny cel z pierścieniem postępu;
  po trzecim zadaniu fanfary, reszta dnia to czysty bonus.
- **↷ Pomiń** — obecne zadanie blokuje? Odłóż je na później bez poczucia winy
  i zobacz następne (wraca przy kolejnym uruchomieniu).
- **📈 Twój tydzień** — miniwykres ukończonych zadań z ostatnich 7 dni.
- **⚙️ Ustawienia** — statystyki postępów, powtórka wprowadzenia, wymazanie
  danych (z podwójnym potwierdzeniem).
- **👋 Onboarding** — 4 szybkie karty przy pierwszym uruchomieniu, bez ściany tekstu.
- **🔔 Powiadomienie timera** — koniec sesji skupienia da znać nawet przy
  zablokowanym ekranie; odliczanie liczone od daty końcowej, więc działa w tle.

Dane trzymane lokalnie na telefonie (JSON w Documents) — zero kont, zero serwera,
zero rozpraszaczy. Interfejs w 100% po polsku.

## Wymagania

- Mac z **Xcode 16** (lub nowszym)
- iOS **17.0+** na telefonie
- Darmowe konto Apple ID wystarczy do instalacji na własnym iPhonie

## Uruchomienie na iPhonie

1. Otwórz `Ogarnito.xcodeproj` w Xcode.
2. W ustawieniach targetu **Ogarnito → Signing & Capabilities** wybierz swój
   **Team** (wystarczy osobiste Apple ID) — Xcode sam ogarnie podpisywanie.
   W razie konfliktu bundle ID zmień `pl.krzysztofpe.Ogarnito` na własny.
3. Podłącz iPhone'a kablem (lub przez Wi-Fi), wybierz go jako urządzenie docelowe
   i wciśnij **⌘R**.
4. Przy pierwszym uruchomieniu na telefonie: Ustawienia → Ogólne →
   Zarządzanie VPN i urządzeniami → zaufaj swojemu certyfikatowi dewelopera.

> Uwaga: przy darmowym koncie Apple ID aplikacja wygasa po 7 dniach —
> wystarczy ponownie wgrać ją z Xcode. Płatne konto deweloperskie (99 USD/rok)
> zdejmuje ten limit i pozwala na TestFlight/App Store.

## Publikacja w App Store

Krok po kroku (z gotowym opisem, słowami kluczowymi i odpowiedziami do
formularza prywatności): zobacz **[APPSTORE.md](APPSTORE.md)**.

## Struktura projektu

```
Ogarnito/
├── OgarnitoApp.swift        # punkt wejścia
├── Models.swift             # model danych, kolory motywu, wspólne UI, haptyka
├── AppStore.swift           # stan aplikacji, XP/poziomy, persystencja JSON
├── Notifications.swift      # lokalne powiadomienie o końcu sesji skupienia
├── PrivacyInfo.xcprivacy    # manifest prywatności (wymagany przez Apple)
└── Views/
    ├── RootView.swift       # TabView, nagłówek XP + SOS + ustawienia, konfetti
    ├── OnboardingView.swift # 4 karty przy pierwszym uruchomieniu
    ├── SettingsView.swift   # statystyki, prywatność, wymazanie danych
    ├── NowView.swift        # „Teraz" — jedno zadanie, jeden krok, odblokowanie
    ├── TasksView.swift      # brain dump + lista zadań z mikro-krokami
    ├── HabitsView.swift     # nawyki, siatka 7 dni, streaki
    ├── FocusTimerView.swift # timer skupienia z pierścieniem
    ├── LifeView.swift       # „Życie": jedzenie, woda, stres, portfel impulsów
    └── BreathingView.swift  # oddech 4-4-4-4 + uziemienie 5-4-3-2-1
```

Czysty SwiftUI, bez zewnętrznych zależności.
