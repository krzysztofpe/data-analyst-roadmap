# ⚡ Ogarnito — natywna aplikacja iOS dla ADHD-owców

Planer zadań i nawyków napisany w **Swift / SwiftUI**: buduj nawyki i *get shit done* —
bez przytłaczających list, za to z dopaminą.

## Funkcje

- **🎯 Teraz** — pokazuje **jedno** zadanie naraz (i tylko jego następny krok), żeby nie
  przytłaczać. Tryb „🐸 zjedz żabę": oznacz najważniejszą rzecz dnia.
- **📝 Zadania + brain dump** — wrzucasz wszystko z głowy bez planowania i oceniania.
  Każde zadanie rozbijesz na mikro-kroki (max 10 minut każdy).
- **🔥 Nawyki z dniem łaski ❄️** — siatka 7 dni i streak, który **nie zeruje się**
  po jednej wpadce. Zerwany łańcuch to najczęstszy powód kasowania apek
  nawykowych — tutaj kosztuje płatek śniegu, nie cały dorobek.
- **🎙️ „Hej Siri, dodaj zadanie do Ogarnito"** — myśl trafia na listę bez
  odblokowywania telefonu i bez wypadania z tego, co właśnie robisz.
- **💜 Ciepły powrót po przerwie** — po kilku dniach nieobecności apka wita
  bez wyrzutów i bez sterty zaległości (bo ich tu w ogóle nie ma).
- **✓ „Zrobiłem coś spoza listy"** — zalicz robotę, której nigdy nie zaplanowałeś.
  Połowa ADHD-dnia to takie rzeczy i normalnie nikt za nie nie klaszcze.
- **⏱️ Timer skupienia przypięty do zadania** — 2/5/15/25 minut. Umowa z mózgiem:
  pracujesz *tylko tyle*, potem możesz przestać. Ekran nie gaśnie w trakcie sesji.
  Timer wie, nad czym siedzisz, a domknięte sesje dopisują minuty do zadania —
  po tygodniu widzisz **ile te rzeczy naprawdę zajmują**, zamiast zgadywać.
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
- **🏆 Cel dnia (1–5 zadań)** — mały, osiągalny cel z pierścieniem postępu;
  po jego zrobieniu fanfary, reszta dnia to czysty bonus. Ustawiasz go pod
  siebie — ma być do zrobienia w gorszy dzień, nie ambitny.
- **🗄️ Archiwum** — zrobione z poprzednich dni schodzą z oczu do zwijanej
  sekcji, żeby lista nie puchła i nie przytłaczała samym rozmiarem.
- **↷ Pomiń** — obecne zadanie blokuje? Odłóż je na później bez poczucia winy
  i zobacz następne (wraca przy kolejnym uruchomieniu).
- **⚡🪫 Poziomy energii** — oznacz zadania „na pełną baterię" albo „na zombie
  mode", a potem jednym tapnięciem filtruj widok „Teraz" pod obecny stan mocy.
- **🎲 Wylosuj** — paraliż decyzyjny? Kostka wybiera zadanie za Ciebie.
- **🔔 Dzienne przypomnienia** — plan dnia rano, jedzenie w południe, domknięcie
  wieczorem; własne godziny, włączane w ustawieniach.
- **💾 Kopia zapasowa** — eksport i przywracanie wszystkich danych jako JSON
  (przez arkusz udostępniania / aplikację Pliki).
- **📈 Twój tydzień** — miniwykres ukończonych zadań z ostatnich 7 dni.
- **⚙️ Ustawienia** — cel dnia, wibracje, statystyki postępów, powtórka
  wprowadzenia, wymazanie danych (z podwójnym potwierdzeniem).
- **♿ Dostępność** — etykiety VoiceOver na przyciskach-ikonach, wyłączalne
  wibracje i poszanowanie systemowego „Ogranicz ruch" (bez konfetti).
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

## Testy logiki (bez Xcode)

```bash
python3 Tests/run-logic-tests.py
```

Skrypt wyciąga prawdziwy kod ze źródeł (algorytm streaka i typy danych),
kompiluje go jako samodzielne programy i uruchamia — więc testuje oryginał,
a nie jego kopię. Sprawdza m.in. liczenie streaka z dniem łaski oraz to, czy
zapisy ze starszych wersji aplikacji wczytują się bez utraty danych.
Wymaga tylko kompilatora Swift w `PATH`.

Sam kod widoków można sprawdzić składniowo bez Xcode:

```bash
swiftc -parse -swift-version 5 $(find Ogarnito -name '*.swift')
```

## Struktura projektu

```
Ogarnito/
├── OgarnitoApp.swift        # punkt wejścia
├── Models.swift             # model danych, kolory motywu, wspólne UI, haptyka
├── AppStore.swift           # stan aplikacji, XP/poziomy, persystencja JSON
├── Notifications.swift      # lokalne powiadomienie o końcu sesji skupienia
├── Reminders.swift          # codzienne przypomnienia (plan / jedzenie / wieczór)
├── AppIntents.swift         # przechwytywanie zadań przez Siri i Skróty
├── TaskInbox.swift          # skrzynka na zadania złapane spoza aplikacji
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
