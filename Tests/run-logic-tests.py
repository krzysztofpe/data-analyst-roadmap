#!/usr/bin/env python3
"""
Testy czystej logiki Ogarnito — bez Xcode i bez symulatora.

Wyciąga prawdziwy kod ze źródeł aplikacji (algorytm streaka i typy danych),
podstawia go do samodzielnych programów w Swift, kompiluje i uruchamia.
Dzięki temu testy sprawdzają oryginał, a nie jego kopię, i nie mogą się
z nim rozjechać.

Wymaga kompilatora Swift w PATH (na Macu wystarczy Xcode, na Linuksie
toolchain ze swift.org). Uruchomienie:

    python3 Tests/run-logic-tests.py
"""

import pathlib
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "Ogarnito"


def block(text: str, header: str) -> str:
    """Zwraca deklarację zaczynającą się od `header` wraz z jej ciałem."""
    start = text.index(header)
    depth = 0
    for i in range(text.index("{", start), len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
    raise ValueError(f"nie znaleziono końca bloku: {header}")


STUBS = '''import Foundation
struct Habit { var name: String; var doneDays: Set<String> = [] }
enum Dates {
    static let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian); return f
    }()
    static func dayKey(_ date: Date = Date()) -> String { dayFormatter.string(from: date) }
}
struct StreakInfo { var count: Int; var graceDay: String? }
'''

STREAK_CASES = '''
func days(_ offsets: [Int]) -> Set<String> {
    let cal = Calendar.current
    return Set(offsets.compactMap {
        cal.date(byAdding: .day, value: -$0, to: Date()).map { Dates.dayKey($0) }
    })
}
struct Case { let name: String; let done: [Int]; let count: Int; let grace: Bool }
let cases: [Case] = [
    Case(name: "nowy nawyk, zrobiony tylko dzis",         done: [0],           count: 1,  grace: false),
    Case(name: "zrobiony wczoraj, dzis jeszcze nie",      done: [1],           count: 1,  grace: false),
    Case(name: "trzy dni z rzedu",                        done: [0,1,2],       count: 3,  grace: false),
    Case(name: "wpadka wczoraj, wczesniej dwa dni",       done: [0,2,3],       count: 3,  grace: true),
    Case(name: "dwie wpadki pod rzad koncza lancuch",     done: [0,3,4],       count: 1,  grace: false),
    Case(name: "pusty nawyk",                             done: [],            count: 0,  grace: false),
    Case(name: "dzis nie, wczoraj nie",                   done: [2,3],         count: 0,  grace: false),
    Case(name: "dlugi ciag 10 dni",                       done: Array(0...9),  count: 10, grace: false),
    Case(name: "dziura w srodku dlugiego ciagu",          done: [0,1,2,4,5,6], count: 6,  grace: true),
    Case(name: "dwie dziury - liczy tylko do drugiej",    done: [0,2,4,5],     count: 2,  grace: true),
]
var fail = 0
for c in cases {
    let r = streakInfo(for: Habit(name: c.name, doneDays: days(c.done)))
    let g = r.graceDay != nil
    let ok = r.count == c.count && g == c.grace
    if !ok { fail += 1 }
    print("\\(ok ? "OK  " : "BLAD") \\(c.name) -> streak \\(r.count), laska \\(g)")
    if !ok { print("      oczekiwano: streak \\(c.count), laska \\(c.grace)") }
}
print("")
exit(fail == 0 ? 0 : 1)
'''

PERSISTENCE_CASES = '''
var fail = 0
func check(_ name: String, _ cond: Bool, _ extra: String = "") {
    print("\\(cond ? "OK  " : "BLAD") \\(name) \\(extra)")
    if !cond { fail += 1 }
}

var t = TodoTask(title: "Pranie")
t.steps = [TaskStep(text: "wrzucic"), TaskStep(text: "wlaczyc", done: true)]
t.isFrog = true; t.energy = .low; t.done = true; t.doneAt = Date()
t.focusMinutes = 45
let h = Habit(name: "Woda", doneDays: ["2026-07-01", "2026-07-02"])
var imp = ImpulseItem(name: "Sluchawki", price: 499.99)
imp.decision = .skipped; imp.decidedAt = Date()
let snap = Snapshot(tasks: [t], habits: [h], xp: 245, impulses: [imp],
                    care: ["2026-07-28": DayCare(meals: ["obiad"], water: 5, focus: 90)])

let data = try! JSONEncoder().encode(snap)
let back = try! JSONDecoder().decode(Snapshot.self, from: data)
check("zadania przezywaja zapis i odczyt",
      back.tasks.first?.title == "Pranie" && back.tasks.first?.steps.count == 2)
check("energia i zaba zachowane",
      back.tasks.first?.energy == .low && back.tasks.first?.isFrog == true)
check("historia nawyku zachowana", back.habits.first?.doneDays == h.doneDays)
check("XP zachowane", back.xp == 245)
check("decyzja o impulsie zachowana",
      back.impulses?.first?.decision == .skipped && back.impulses?.first?.price == 499.99)
check("jedzenie i woda zachowane", back.care?["2026-07-28"]?.water == 5)
check("czas skupienia zachowany",
      back.tasks.first?.focusMinutes == 45 && back.care?["2026-07-28"]?.focus == 90)
check("formatowanie czasu", TimeText.minutes(45) == "45 min"
      && TimeText.minutes(60) == "1 h" && TimeText.minutes(135) == "2 h 15 min")

// Zapis z wczesniejszej wersji apki: bez impulses, care i energy.
let legacy = """
{"tasks":[{"id":"3F2504E0-4F89-11D3-9A0C-0305E82C3301","title":"Stare zadanie",
"steps":[],"done":false,"isFrog":false,"createdAt":770000000}],
"habits":[{"id":"3F2504E0-4F89-11D3-9A0C-0305E82C3302","name":"Stary nawyk",
"doneDays":["2026-01-01"]}],"xp":120}
"""
if let old = try? JSONDecoder().decode(Snapshot.self, from: Data(legacy.utf8)) {
    check("stary zapis wczytuje sie bez utraty danych",
          old.tasks.count == 1 && old.habits.count == 1 && old.xp == 120)
    check("brakujace pola dostaja wartosci domyslne",
          old.impulses == nil && old.care == nil && old.tasks[0].energy == nil)
    check("brak czasu skupienia w starym zapisie nie psuje odczytu",
          old.tasks[0].focusMinutes == nil && old.tasks[0].focusTime == 0)
} else {
    check("stary zapis wczytuje sie bez utraty danych", false, "-> UTRATA DANYCH")
}

check("uszkodzony plik odrzucony bez wywalenia apki",
      (try? JSONDecoder().decode(Snapshot.self, from: Data("nie-json".utf8))) == nil)
print("")
exit(fail == 0 ? 0 : 1)
'''


def build_streak_program() -> str:
    store = (SRC / "AppStore.swift").read_text(encoding="utf-8")
    fn = block(store, "func streakInfo(for habit: Habit) -> StreakInfo {")
    return STUBS + fn + STREAK_CASES


def build_persistence_program() -> str:
    models = (SRC / "Models.swift").read_text(encoding="utf-8")
    store = (SRC / "AppStore.swift").read_text(encoding="utf-8")
    types = [
        "struct TaskStep: Identifiable, Codable, Hashable {",
        "enum EnergyLevel: String, Codable, Hashable {",
        "struct TodoTask: Identifiable, Codable, Hashable {",
        "struct Habit: Identifiable, Codable, Hashable {",
        "struct DayCare: Codable, Hashable {",
        "struct ImpulseItem: Identifiable, Codable, Hashable {",
        "enum TimeText {",
    ]
    parts = [block(models, h) for h in types]
    snapshot = block(store, "private struct Snapshot: Codable {").replace(
        "private struct", "struct")
    return "import Foundation\n" + "\n".join(parts) + "\n" + snapshot + PERSISTENCE_CASES


def run(name: str, program: str, swiftc: str, workdir: pathlib.Path) -> bool:
    print(f"\n--- {name} ---")
    source = workdir / f"{name}.swift"
    binary = workdir / name
    source.write_text(program, encoding="utf-8")
    compiled = subprocess.run(
        [swiftc, "-swift-version", "5", "-o", str(binary), str(source)],
        capture_output=True, text=True)
    if compiled.returncode != 0:
        print("Kompilacja nieudana:")
        print(compiled.stdout + compiled.stderr)
        return False
    result = subprocess.run([str(binary)], capture_output=True, text=True)
    print(result.stdout + result.stderr, end="")
    return result.returncode == 0


def main() -> int:
    swiftc = shutil.which("swiftc")
    if not swiftc:
        print("Nie znaleziono kompilatora Swift (swiftc) w PATH.")
        print("Na Macu: zainstaluj Xcode. Na Linuksie: toolchain ze swift.org.")
        return 2

    with tempfile.TemporaryDirectory() as tmp:
        workdir = pathlib.Path(tmp)
        results = [
            run("streak", build_streak_program(), swiftc, workdir),
            run("persystencja", build_persistence_program(), swiftc, workdir),
        ]

    if all(results):
        print("Wszystkie testy logiki przeszly.")
        return 0
    print("Sa bledy — zobacz wyzej.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
