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
- **⏱️ Timer skupienia** — 5/15/25 minut. Umowa z mózgiem: pracujesz *tylko tyle*,
  potem możesz przestać. Ekran nie gaśnie w trakcie sesji.
- **✨ Dopamina** — XP, poziomy, konfetti, haptyka i pochwały po każdym zrobionym kroku.

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

## Struktura projektu

```
Ogarnito/
├── OgarnitoApp.swift        # punkt wejścia
├── Models.swift             # model danych, kolory motywu, haptyka, klucze dni
├── AppStore.swift           # stan aplikacji, XP/poziomy, persystencja JSON
└── Views/
    ├── RootView.swift       # TabView, nagłówek XP, konfetti, pochwały
    ├── NowView.swift        # „Teraz" — jedno zadanie, jeden krok
    ├── TasksView.swift      # brain dump + lista zadań z mikro-krokami
    ├── HabitsView.swift     # nawyki, siatka 7 dni, streaki
    └── FocusTimerView.swift # timer skupienia z pierścieniem
```

Czysty SwiftUI, bez zewnętrznych zależności.
