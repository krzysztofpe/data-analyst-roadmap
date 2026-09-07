import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published var tasks: [TodoTask] = []
    @Published var habits: [Habit] = []
    @Published var impulses: [ImpulseItem] = []
    @Published var care: [String: DayCare] = [:]
    @Published var xp: Int = 0
    @Published var praise: String?
    @Published var confettiBurst: Int = 0
    @Published var selectedTab: Tab = .now
    @Published var showBreathing = false
    /// Pełnoekranowa interwencja, gdy łapiesz się na bezmyślnym scrollowaniu.
    @Published var showScreenBreak = false
    /// Godzina, od której apka przechodzi w tryb wieczorny.
    @Published var eveningHour: Int {
        didSet { UserDefaults.standard.set(eveningHour, forKey: "eveningHour") }
    }
    /// Ocieplenie ekranu wieczorem — mniej niebieskiego światła z tej aplikacji.
    @Published var eveningTint: Bool {
        didSet { UserDefaults.standard.set(eveningTint, forKey: "eveningTint") }
    }
    /// Ustawiane z innych widoków, żeby timer sam wystartował z zadaną liczbą minut.
    @Published var timerRequest: Int?
    /// Zadanie, nad którym trwa sesja skupienia — timer nie wisi w próżni.
    @Published var focusTaskID: UUID?
    /// Zadania odłożone „nie teraz" — tylko na czas tej sesji, świeże oczy po restarcie.
    @Published var skippedIDs: Set<UUID> = []
    /// Filtr „ile mam teraz mocy" — sesyjny, wpływa na wybór zadania w „Teraz".
    @Published var currentEnergy: EnergyLevel?
    /// Zadanie wskazane kostką 🎲 — ma pierwszeństwo, dopóki nie zostanie zrobione/pominięte.
    @Published var forcedTaskID: UUID?
    /// Ile dni minęło od ostatniego otwarcia — do ciepłego powitania po przerwie.
    @Published var daysAway: Int = 0
    /// Ile zadań dziennie wystarczy, żeby dzień uznać za udany (1–5).
    @Published var dailyGoal: Int {
        didSet { UserDefaults.standard.set(dailyGoal, forKey: "dailyGoal") }
    }

    enum Tab: Hashable { case now, tasks, habits, timer, life }

    private var praiseClearTask: Task<Void, Never>?

    private static let praises = [
        "Sztos! 🎉", "No i git! 💪", "Mózg dostał dopaminkę 🧠✨",
        "Zrobione = lepsze niż idealne ✅", "Kolejny krok bliżej! 🚀",
        "Jesteś maszyną 🔥", "Tak się to robi! 👏", "Boom! 💥", "ADHD 0 : 1 Ty 😎"
    ]

    init() {
        let defaults = UserDefaults.standard
        let savedGoal = defaults.integer(forKey: "dailyGoal")
        dailyGoal = (1...5).contains(savedGoal) ? savedGoal : 3
        let savedHour = defaults.integer(forKey: "eveningHour")
        eveningHour = (17...23).contains(savedHour) ? savedHour : 21
        eveningTint = defaults.object(forKey: "eveningTint") as? Bool ?? true
        load()
        checkReturn()
        drainInbox()
    }

    // MARK: - Wieczór, ekran i sen

    /// Wieczór trwa od ustawionej godziny do 5 rano.
    var isEvening: Bool {
        let h = Calendar.current.component(.hour, from: Date())
        return h >= eveningHour || h < 5
    }

    /// Ile godzin zostało do wyciszenia — do komunikatu w widoku „Życie".
    var hoursToEvening: Int {
        let h = Calendar.current.component(.hour, from: Date())
        return h < eveningHour ? eveningHour - h : 0
    }

    var scrollCatchesToday: Int { todayCare.scrollCatches ?? 0 }

    /// Przyłapanie się na scrollu jest sukcesem, nie wpadką — i tak je nagradzamy.
    func catchScroll() {
        let key = Dates.dayKey()
        var c = care[key] ?? DayCare()
        c.scrollCatches = (c.scrollCatches ?? 0) + 1
        care[key] = c
        reward(7, big: false)
    }

    var windDownToday: Set<String> { todayCare.winddown ?? [] }

    var windDownDone: Bool { windDownToday.count == WindDownStep.allCases.count }

    func toggleWindDown(_ step: WindDownStep) {
        let key = Dates.dayKey()
        var c = care[key] ?? DayCare()
        var done = c.winddown ?? []
        if done.contains(step.rawValue) {
            done.remove(step.rawValue)
            c.winddown = done
            care[key] = c
            save()
        } else {
            done.insert(step.rawValue)
            c.winddown = done
            care[key] = c
            if done.count == WindDownStep.allCases.count {
                reward(12, big: true)
                showPraise("🌙 Dobranoc. Zrobiłeś dziś wystarczająco.")
            } else {
                reward(2, big: false)
            }
        }
    }

    /// Skrót „przerwij scroll" tylko odkłada flagę — ekran otwieramy dopiero,
    /// gdy aplikacja jest na wierzchu.
    func consumePendingScreenBreak() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "pendingScreenBreak") else { return }
        defaults.set(false, forKey: "pendingScreenBreak")
        showScreenBreak = true
    }

    // MARK: - Powrót po przerwie

    /// Zero wyrzutów sumienia: apka tylko odnotowuje, że Cię nie było,
    /// żeby przywitać Cię ciepło zamiast straszyć zaległościami.
    private func checkReturn() {
        let defaults = UserDefaults.standard
        let todayKey = Dates.dayKey()
        if let last = defaults.string(forKey: "lastOpenDay"),
           last != todayKey,
           let lastDate = Dates.dayFormatter.date(from: last),
           let diff = Calendar.current.dateComponents(
               [.day], from: lastDate, to: Date()).day {
            daysAway = max(0, diff)
        }
        defaults.set(todayKey, forKey: "lastOpenDay")
    }

    func dismissWelcomeBack() {
        withAnimation { daysAway = 0 }
    }

    // MARK: - Skrzynka z Siri / Skrótów

    /// Zadania dorzucone przez Siri lub Skróty lądują w osobnym pliku,
    /// żeby nie ścigać się o zapis z działającą aplikacją. Tu je zbieramy.
    func drainInbox() {
        let captured = TaskInbox.drain()
        guard !captured.isEmpty else { return }
        for title in captured.reversed() {
            tasks.insert(TodoTask(title: title), at: 0)
        }
        save()
        showPraise("🎙️ Złapane: \(captured.count) \(captured.count == 1 ? "zadanie" : "zadania")")
    }

    // MARK: - XP / poziomy

    var level: Int { Int((Double(xp) / 60).squareRoot()) + 1 }

    var levelProgress: Double {
        let base = 60 * (level - 1) * (level - 1)
        let next = 60 * level * level
        return Double(xp - base) / Double(next - base)
    }

    func showPraise(_ text: String) {
        praise = text
        praiseClearTask?.cancel()
        praiseClearTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }
            self?.praise = nil
        }
    }

    func reward(_ points: Int, big: Bool) {
        let levelBefore = level
        xp += points
        if big { confettiBurst += 1 }
        if level > levelBefore {
            confettiBurst += 1
            showPraise("🏆 POZIOM \(level)! Rośniesz w siłę!")
        } else {
            showPraise("\(Self.praises.randomElement()!)  +\(points) XP")
        }
        Haptics.success()
        save()
    }

    /// XP bez fanfar — do drobiazgów typu szklanka wody.
    func quietXP(_ points: Int) {
        xp += points
        save()
    }

    // MARK: - Zadania

    /// Do zrobienia: żaba na wierzchu, potem od najnowszych.
    var activeTasks: [TodoTask] {
        tasks.filter { !$0.done }
            .sorted { a, b in
                if a.isFrog != b.isFrog { return a.isFrog }
                return a.createdAt > b.createdAt
            }
    }

    /// Zrobione w poprzednich dniach — schodzą z oczu do archiwum, żeby lista
    /// nie puchła w nieskończoność i nie przytłaczała samym rozmiarem.
    var archivedTasks: [TodoTask] {
        tasks.filter { task in
            guard task.done else { return false }
            guard let d = task.doneAt else { return true }
            return Dates.dayKey(d) != Dates.dayKey()
        }
        .sorted { ($0.doneAt ?? .distantPast) > ($1.doneAt ?? .distantPast) }
    }

    func clearArchive() {
        let archivedIDs = Set(archivedTasks.map(\.id))
        tasks.removeAll { archivedIDs.contains($0.id) }
        save()
    }

    /// Jedno zadanie do pokazania w widoku „Teraz": kostka > żaba > dopasowane
    /// do energii > najnowsze otwarte.
    var currentTask: TodoTask? {
        let open = activeTasks
        if let forced = forcedTaskID, let task = open.first(where: { $0.id == forced }) {
            return task
        }
        let fresh = open.filter { !skippedIDs.contains($0.id) }
        let pool: [TodoTask]
        if let level = currentEnergy {
            let matching = fresh.filter { $0.energy == nil || $0.energy == level }
            pool = matching.isEmpty ? fresh : matching
        } else {
            pool = fresh
        }
        return pool.first { $0.isFrog } ?? pool.first ?? open.first
    }

    var openTaskCount: Int { tasks.filter { !$0.done }.count }

    /// „Nie teraz" — pokaż następne otwarte zadanie zamiast obecnego.
    func skipCurrentTask() {
        guard let current = currentTask else { return }
        if forcedTaskID == current.id { forcedTaskID = nil }
        skippedIDs.insert(current.id)
        let open = tasks.filter { !$0.done }
        if open.allSatisfy({ skippedIDs.contains($0.id) }) {
            // Wszystko pominięte — wracają wszystkie poza właśnie odłożonym.
            skippedIDs = [current.id]
        }
        Haptics.tap()
    }

    /// Paraliż decyzyjny? Kostka wybiera za Ciebie.
    func pickRandomTask() {
        let open = tasks.filter { !$0.done }
        let candidates = open.filter { $0.id != currentTask?.id }
        guard let pick = (candidates.isEmpty ? open : candidates).randomElement() else { return }
        forcedTaskID = pick.id
        showPraise("🎲 Los wybrał. Nie dyskutuj z kostką!")
        Haptics.tap()
    }

    func setEnergy(_ id: TodoTask.ID, _ level: EnergyLevel?) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[i].energy = level
        save()
    }

    var doneToday: [TodoTask] {
        tasks.filter { t in
            guard let d = t.doneAt else { return false }
            return Dates.dayKey(d) == Dates.dayKey()
        }
    }

    func addTask(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.insert(TodoTask(title: trimmed), at: 0)
        Haptics.tap()
        save()
    }

    func toggleTask(_ id: TodoTask.ID) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        if tasks[i].done {
            tasks[i].done = false
            tasks[i].doneAt = nil
            save()
        } else {
            completeTask(at: i)
        }
    }

    private func completeTask(at i: Int) {
        tasks[i].done = true
        tasks[i].doneAt = Date()
        for j in tasks[i].steps.indices { tasks[i].steps[j].done = true }
        skippedIDs.remove(tasks[i].id)
        if forcedTaskID == tasks[i].id { forcedTaskID = nil }
        reward(10, big: true)
        celebrateIfGoalReached()
    }

    /// Cel dnia osiągnięty — jednorazowe fanfary, bez licytowania się dalej.
    private func celebrateIfGoalReached() {
        guard doneToday.count == dailyGoal else { return }
        showPraise("🏆 Cel dnia zrobiony! Reszta to czysty bonus.")
        confettiBurst += 1
    }

    func toggleStep(taskID: TodoTask.ID, stepID: TaskStep.ID) {
        guard let i = tasks.firstIndex(where: { $0.id == taskID }),
              let j = tasks[i].steps.firstIndex(where: { $0.id == stepID }) else { return }
        tasks[i].steps[j].done.toggle()
        if tasks[i].steps[j].done {
            if !tasks[i].done && tasks[i].steps.allSatisfy(\.done) {
                completeTask(at: i)
            } else {
                reward(3, big: false)
            }
        } else {
            save()
        }
    }

    func addStep(taskID: TodoTask.ID, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let i = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[i].steps.append(TaskStep(text: trimmed))
        if tasks[i].done {
            tasks[i].done = false
            tasks[i].doneAt = nil
        }
        save()
    }

    /// Zrobione, choć nigdy nie było na liście. ADHD-dzień w połowie składa
    /// się z takich rzeczy — i normalnie nikt za nie nie klaszcze.
    func logDoneOutsideList(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var task = TodoTask(title: trimmed)
        task.done = true
        task.doneAt = Date()
        tasks.insert(task, at: 0)
        reward(10, big: true)
        celebrateIfGoalReached()
    }

    func deleteTask(_ id: TodoTask.ID) {
        tasks.removeAll { $0.id == id }
        if forcedTaskID == id { forcedTaskID = nil }
        save()
    }

    func renameTask(_ id: TodoTask.ID, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[i].title = trimmed
        save()
    }

    /// Tylko jedna żaba naraz — najważniejsza rzecz dnia.
    func toggleFrog(_ id: TodoTask.ID) {
        for i in tasks.indices {
            tasks[i].isFrog = (tasks[i].id == id) ? !tasks[i].isFrog : false
        }
        Haptics.tap()
        save()
    }

    // MARK: - Nawyki

    func addHabit(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        habits.append(Habit(name: trimmed))
        save()
    }

    func deleteHabit(_ id: Habit.ID) {
        habits.removeAll { $0.id == id }
        save()
    }

    func toggleHabitToday(_ id: Habit.ID) {
        guard let i = habits.firstIndex(where: { $0.id == id }) else { return }
        let key = Dates.dayKey()
        if habits[i].doneDays.contains(key) {
            habits[i].doneDays.remove(key)
            save()
        } else {
            habits[i].doneDays.insert(key)
            reward(5, big: false)
        }
    }

    struct StreakInfo {
        var count: Int
        /// Dzień uratowany łaską — pokazywany w siatce jako ❄️.
        var graceDay: String?
    }

    /// Streak z jednym dniem łaski: pojedynczy pominięty dzień NIE zeruje
    /// łańcucha. Zerwany streak to najczęstszy powód porzucania apek przez
    /// osoby z ADHD — tu wpadka kosztuje płatek śniegu, nie cały dorobek.
    func streakInfo(for habit: Habit) -> StreakInfo {
        let cal = Calendar.current
        var day = Date()
        // Niezrobione „dzisiaj" jeszcze nie łamie łańcucha — liczymy od wczoraj.
        if !habit.doneDays.contains(Dates.dayKey(day)) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: day) else {
                return StreakInfo(count: 0, graceDay: nil)
            }
            day = yesterday
        }
        var count = 0
        var graceDay: String?
        while true {
            let key = Dates.dayKey(day)
            if habit.doneDays.contains(key) {
                count += 1
            } else if graceDay == nil, count > 0,
                      let before = cal.date(byAdding: .day, value: -1, to: day),
                      habit.doneDays.contains(Dates.dayKey(before)) {
                // Łaska tylko wtedy, gdy realnie łączy dwa zrobione dni —
                // inaczej ❄️ wyskakiwałoby przy każdym świeżym nawyku.
                graceDay = key
            } else {
                break
            }
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return StreakInfo(count: count, graceDay: graceDay)
    }

    func streak(for habit: Habit) -> Int { streakInfo(for: habit).count }

    // MARK: - Statystyki tygodnia

    struct DayStat: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
        let isToday: Bool
    }

    /// Zadania ukończone w każdym z ostatnich 7 dni — do wykresu w widoku „Teraz".
    var weekStats: [DayStat] {
        let cal = Calendar.current
        return (0..<7).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let key = Dates.dayKey(day)
            let count = tasks.filter { t in
                guard let d = t.doneAt else { return false }
                return Dates.dayKey(d) == key
            }.count
            let weekday = cal.component(.weekday, from: day) - 1
            return DayStat(label: Dates.shortWeekdays[weekday],
                           count: count,
                           isToday: offset == 0)
        }
    }

    // MARK: - Reset

    func resetAll() {
        tasks = []
        habits = []
        impulses = []
        care = [:]
        xp = 0
        skippedIDs = []
        forcedTaskID = nil
        focusTaskID = nil
        currentEnergy = nil
        save()
    }

    // MARK: - Kopia zapasowa

    /// Zapisuje pełną kopię danych do pliku tymczasowego (do udostępnienia).
    func writeBackupFile() -> URL? {
        let snapshot = Snapshot(tasks: tasks, habits: habits, xp: xp,
                                impulses: impulses, care: care)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(snapshot) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ogarnito-backup.json")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    /// Wczytuje kopię zapasową, zastępując obecne dane. Zwraca false przy złym pliku.
    @discardableResult
    func importBackup(_ data: Data) -> Bool {
        guard let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return false
        }
        tasks = snapshot.tasks
        habits = snapshot.habits
        xp = snapshot.xp
        impulses = snapshot.impulses ?? []
        care = snapshot.care ?? [:]
        skippedIDs = []
        forcedTaskID = nil
        save()
        showPraise("📥 Dane przywrócone z kopii!")
        Haptics.success()
        return true
    }

    // MARK: - Jedzenie i woda

    var todayCare: DayCare { care[Dates.dayKey()] ?? DayCare() }

    func toggleMeal(_ meal: String) {
        let key = Dates.dayKey()
        var c = care[key] ?? DayCare()
        if c.meals.contains(meal) {
            c.meals.remove(meal)
            care[key] = c
            save()
        } else {
            c.meals.insert(meal)
            care[key] = c
            reward(2, big: false)
        }
    }

    func changeWater(_ delta: Int) {
        let key = Dates.dayKey()
        var c = care[key] ?? DayCare()
        let newValue = max(0, c.water + delta)
        if newValue > c.water && newValue <= 8 { quietXP(1) }
        c.water = newValue
        care[key] = c
        if delta > 0 { Haptics.tap() }
        save()
    }

    // MARK: - Skupienie

    var focusTask: TodoTask? {
        guard let id = focusTaskID else { return nil }
        return tasks.first { $0.id == id }
    }

    /// Odpala sesję skupienia przypiętą do konkretnego zadania.
    func startFocus(on taskID: UUID?, minutes: Int) {
        focusTaskID = taskID
        timerRequest = minutes
        selectedTab = .timer
    }

    /// Domknięta sesja dopisuje minuty do zadania i do dzisiejszego licznika.
    /// Liczymy tylko sesje doprowadzone do końca — inaczej dane byłyby ściemą.
    func logFocus(minutes: Int) {
        guard minutes > 0 else { return }
        if let id = focusTaskID, let i = tasks.firstIndex(where: { $0.id == id }) {
            tasks[i].focusMinutes = tasks[i].focusTime + minutes
        }
        let key = Dates.dayKey()
        var c = care[key] ?? DayCare()
        c.focus = (c.focus ?? 0) + minutes
        care[key] = c
        save()
    }

    var focusToday: Int { todayCare.focus ?? 0 }

    var focusTotal: Int {
        care.values.reduce(0) { $0 + ($1.focus ?? 0) }
    }

    // MARK: - Oddech / stres

    func finishBreathing(cycles: Int) {
        showBreathing = false
        if cycles >= 3 { reward(6, big: false) }
    }

    // MARK: - Portfel impulsów

    var pendingImpulses: [ImpulseItem] {
        impulses.filter { $0.decision == nil }.sorted { $0.createdAt < $1.createdAt }
    }

    var decidedImpulses: [ImpulseItem] {
        impulses.filter { $0.decision != nil }
            .sorted { ($0.decidedAt ?? .distantPast) > ($1.decidedAt ?? .distantPast) }
    }

    var savedTotal: Double {
        impulses.filter { $0.decision == .skipped }.reduce(0) { $0 + $1.price }
    }

    func addImpulse(name: String, price: Double) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        impulses.insert(ImpulseItem(name: trimmed, price: max(0, price)), at: 0)
        Haptics.tap()
        save()
    }

    func decideImpulse(_ id: ImpulseItem.ID, skipped: Bool) {
        guard let i = impulses.firstIndex(where: { $0.id == id }) else { return }
        impulses[i].decision = skipped ? .skipped : .bought
        impulses[i].decidedAt = Date()
        if skipped {
            reward(15, big: true)
        } else {
            save()
        }
    }

    // MARK: - Persystencja (JSON w Documents)

    private struct Snapshot: Codable {
        var tasks: [TodoTask]
        var habits: [Habit]
        var xp: Int
        // Nowsze pola jako opcjonalne, żeby starsze zapisy dalej się wczytywały.
        var impulses: [ImpulseItem]?
        var care: [String: DayCare]?
    }

    private static var fileURL: URL {
        URL.documentsDirectory.appending(path: "ogarnito.json")
    }

    func save() {
        let snapshot = Snapshot(tasks: tasks, habits: habits, xp: xp,
                                impulses: impulses, care: care)
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: Self.fileURL, options: .atomic)
        } catch {
            print("Ogarnito: zapis nieudany — \(error)")
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        tasks = snapshot.tasks
        habits = snapshot.habits
        xp = snapshot.xp
        impulses = snapshot.impulses ?? []
        care = snapshot.care ?? [:]
    }
}
