# 🚀 Publikacja Ogarnito w App Store — checklista

Wszystko w projekcie jest przygotowane (ikona 1024, manifest prywatności,
deklaracja szyfrowania, onboarding). Poniżej kroki, które musisz zrobić
na Macu i w App Store Connect.

## Wymagania

- [ ] **Apple Developer Program** — płatne konto (99 USD/rok):
      https://developer.apple.com/programs/enroll/
- [ ] Mac z **Xcode 16+**

## 1. Projekt w Xcode (5 minut)

- [ ] Otwórz `Ogarnito.xcodeproj`.
- [ ] Target **Ogarnito → Signing & Capabilities**: wybierz swój Team.
- [ ] Zmień `PRODUCT_BUNDLE_IDENTIFIER` (`pl.krzysztofpe.Ogarnito`) na własny,
      unikalny — musi się zgadzać z tym, co zarejestrujesz w App Store Connect.
- [ ] Zbuduj na symulatorze i swoim iPhonie — sprawdź, że wszystko działa.

## 2. App Store Connect — nowa aplikacja

- [ ] https://appstoreconnect.apple.com → Apps → **+** → New App.
- [ ] Platforma: iOS · Nazwa: **Ogarnito** (jeśli zajęta, np. „Ogarnito —
      planer ADHD") · Język: polski · Bundle ID: ten z kroku 1 · SKU: dowolne.

## 3. Zrzuty ekranu (wymagane)

- [ ] W symulatorze **iPhone 16 Pro Max** zrób ⌘S na ekranach: Teraz, Zadania,
      Nawyki, Timer, Życie, Oddech (min. 3, max 10 zrzutów).
- [ ] Rozmiar 6.9" (1320×2868) wystarczy — Apple przeskaluje na mniejsze.

## 4. Metadane — gotowe do wklejenia

**Podtytuł (30 znaków):**
> Plan dnia dla głowy z ADHD

**Opis:**
> Ogarnito to planer zrobiony pod mózg z ADHD — nie kolejna lista rzeczy,
> które Cię przytłoczą.
>
> 🎯 JEDNO ZADANIE NARAZ — widzisz tylko następny mały krok, nie górę roboty.
> 🧠 BRAIN DUMP — wyrzuć wszystko z głowy w 5 sekund, apka pamięta za Ciebie.
> 🔪 MIKRO-KROKI — rozbij każde zadanie na kawałki po maks 10 minut.
> 🐸 ZJEDZ ŻABĘ — oznacz najważniejszą rzecz dnia i zrób ją najpierw.
> ⏱️ TIMER SKUPIENIA — 2/5/15/25 minut. Umowa z mózgiem: tylko tyle, potem
> możesz przestać. Powiadomienie da znać, kiedy czas minie.
> 😩 „NIE MOGĘ ZACZĄĆ" — tryb odblokowania prokrastynacji: 2 minuty byle jak,
> śmiesznie mały krok albo najpierw wydech.
> 🔥 NAWYKI — streaki bez presji: jeden pominięty dzień to nie porażka.
> 🍽️ JEDZENIE I WODA — bo ADHD-mózg potrafi zapomnieć o obiedzie.
> 💸 PORTFEL IMPULSÓW — impulsywny zakup? 48 godzin poczekalni. Impuls mija,
> kasa zostaje — apka sumuje, ile zaoszczędzasz.
> 🌬️ ODDECH RATUNKOWY — oddech 4-4-4-4 i uziemienie 5-4-3-2-1 na stres,
> jedno tapnięcie z każdego miejsca w aplikacji.
> ✨ DOPAMINA — XP, poziomy, konfetti i pochwały po każdym kroku.
>
> Wszystko działa offline. Twoje dane zostają na Twoim telefonie — zero kont,
> zero chmury, zero śledzenia.

**Słowa kluczowe (100 znaków):**
> adhd,planer,zadania,nawyki,skupienie,pomodoro,prokrastynacja,brain dump,streak,timer

**Kategoria:** Productivity · **Age rating:** 4+

## 5. Prywatność i zgodność

- [ ] App Privacy → **Data Not Collected** (apka niczego nie zbiera ani nie
      wysyła; w repo jest `PrivacyInfo.xcprivacy`).
- [ ] Export compliance: zadeklarowane w projekcie
      (`ITSAppUsesNonExemptEncryption = NO`). Jeśli App Store Connect mimo to
      zapyta o szyfrowanie — odpowiedz „None of the algorithms mentioned above".

## 6. Upload i recenzja

- [ ] Xcode: wybierz urządzenie **Any iOS Device (arm64)** →
      **Product → Archive** → Organizer → **Distribute App → App Store Connect**.
- [ ] (Zalecane) Najpierw **TestFlight** — potestuj tydzień na własnym telefonie.
- [ ] W App Store Connect wybierz build, uzupełnij „What's New", wyślij do
      recenzji. W Review Notes napisz: *aplikacja działa w pełni offline,
      nie wymaga konta ani logowania*.
- [ ] Recenzja trwa zwykle 1–2 dni robocze.

## Po publikacji

- Kolejne wydania: podbij `MARKETING_VERSION` (np. 1.1) i `CURRENT_PROJECT_VERSION`
  (build, np. 2), archiwizuj i wysyłaj ponownie.
