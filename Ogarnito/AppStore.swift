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
    /// Ustawiane z innych widoków, żeby timer sam wystartował z zadaną liczbą minut.
    @Published var timerRequest: Int?
    /// Zadania odłożone „nie teraz" — tylko na czas tej sesji, świeże oczy po restarcie.
    @Published var skippedIDs: Set<UUID> = []

    enum Tab: Hashable { case now, tasks, habits, timer, life }

    private var praiseClearTask: Task<Void, Never>?

    private static let praises = [
        "Sztos! 🎉", "No i git! 💪", "Mózg dostał dopaminkę 🧠✨",
        "Zrobione = lepsze niż idealne ✅", "Kolejny krok bliżej! 🚀",
        "Jesteś maszyną 🔥", "Tak się to robi! 👏", "Boom! 💥", "ADHD 0 : 1 Ty 😎"
    ]

    init() {
        load()
    }

    // MARK: - XP / poziomy

    var level: Int { Int((Double(xp) / 60).squareRoot()) + 1 }

    var levelProgress: Double {
        let base = 60 * (level - 1) * (level - 1)
        let next = 60 * level * level
        return Double(xp - base) / Double(next - base)
    }

    func reward(_ points: Int, big: Bool) {
        let levelBefore = level
        xp += points
        praise = "\(Self.praises.randomElement()!)  +\(points) XP"
        if big { confettiBurst += 1 }
        if level > levelBefore {
            praise = "🏆 POZIOM \(level)! Rośniesz w siłę!"
            confettiBurst += 1
        }
        Haptics.success()
        praiseClearTask?.cancel()
        praiseClearTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }
            self?.praise = nil
        }
        save()
    }

    /// XP bez fanfar — do drobiazgów typu szklanka wody.
    func quietXP(_ points: Int) {
        xp += points
        save()
    }

    // MARK: - Zadania

    var sortedTasks: [TodoTask] {
        tasks.sorted { a, b in
            if a.done != b.done { return !a.done }
            if a.isFrog != b.isFrog { return a.isFrog }
            return a.createdAt > b.createdAt
        }
    }

    /// Jedno zadanie do pokazania w widoku „Teraz": najpierw żaba, potem najnowsze otwarte.
    var currentTask: TodoTask? {
        let open = sortedTasks.filter { !$0.done }
        return open.first { $0.isFrog && !skippedIDs.contains($0.id) }
            ?? open.first { !skippedIDs.contains($0.id) }
            ?? open.first
    }

    var openTaskCount: Int { tasks.filter { !$0.done }.count }

    /// „Nie teraz" — pokaż następne otwarte zadanie zamiast obecnego.
    func skipCurrentTask() {
        guard let current = currentTask else { return }
        skippedIDs.insert(current.id)
        let open = tasks.filter { !$0.done }
        if open.allSatisfy({ skippedIDs.contains($0.id) }) {
            // Wszystko pominięte — wracają wszystkie poza właśnie odłożonym.
            skippedIDs = [current.id]
        }
        Haptics.tap()
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
        reward(10, big: true)
        if doneToday.count == 3 {
            praise = "🏆 Dzisiejsza trójka zrobiona! Reszta to czysty bonus."
            confettiBurst += 1
        }
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

    func deleteTask(_ id: TodoTask.ID) {
        tasks.removeAll { $0.id == id }
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

    /// Streak liczony wstecz; niezrobione „dzisiaj" jeszcze nie łamie łańcucha.
    func streak(for habit: Habit) -> Int {
        var day = Date()
        let cal = Calendar.current
        if !habit.doneDays.contains(Dates.dayKey(day)) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var count = 0
        while habit.doneDays.contains(Dates.dayKey(day)) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

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
        save()
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
