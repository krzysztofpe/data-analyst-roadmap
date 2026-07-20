# ⚡ Ogarnito — planer dla ADHD

Aplikacja webowa (PWA) na iPhone'a dla osób z ADHD: buduj nawyki i *get shit done* —
bez przytłaczających list, za to z dopaminą.

## Co robi

- **🎯 Teraz** — pokazuje **jedno** zadanie naraz (i tylko jego następny krok), żeby nie
  przytłaczać. Tryb „🐸 zjedz żabę": oznacz najważniejszą rzecz dnia.
- **📝 Zadania + brain dump** — wrzucasz wszystko z głowy bez planowania i oceniania.
  Każde zadanie rozbijesz nożem 🔪 na mikro-kroki (max 10 minut każdy).
- **🔥 Nawyki** — siatka ostatnich 7 dni i licznik streaka. Nie przerywaj łańcucha —
  a jak przerwiesz, wracasz następnego dnia, bez dramatu.
- **⏱️ Timer** — 5/15/25 minut. Umowa z mózgiem: pracujesz *tylko tyle*, potem możesz
  przestać. Ekran nie gaśnie w trakcie (Wake Lock).
- **✨ Dopamina** — XP, poziomy, konfetti i pochwały po każdym zrobionym kroku.

Wszystko działa **offline** i trzyma dane lokalnie na telefonie (localStorage) —
zero kont, zero serwera, zero rozpraszaczy.

## Instalacja na iPhonie

1. Wejdź na adres aplikacji w **Safari** (po wdrożeniu na GitHub Pages:
   `https://<twoja-nazwa>.github.io/data-analyst-roadmap/`).
2. Kliknij przycisk **Udostępnij** (kwadrat ze strzałką).
3. Wybierz **„Do ekranu początkowego"** (Add to Home Screen).
4. Gotowe — apka działa na pełnym ekranie jak natywna, offline też.

## Hosting (GitHub Pages)

W repo jest workflow `.github/workflows/deploy-app.yml`, który po wypchnięciu na `main`
publikuje katalog `adhd-app/` na GitHub Pages. Jeśli Pages nie było wcześniej włączone,
workflow włączy je automatycznie (Settings → Pages → Source: GitHub Actions).

## Uruchomienie lokalne

```bash
cd adhd-app
python3 -m http.server 8000
# otwórz http://localhost:8000
```

## Stack

Czysty HTML + CSS + JS w jednym pliku, bez frameworków i zależności.
Manifest PWA + service worker (cache-first) dla trybu offline.
