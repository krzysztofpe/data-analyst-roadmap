import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published var tasks: [TodoTask] = []
    @Published var habits: [Habit] = []
    @Published var xp: Int = 0
    @Published var praise: String?
    @Published var confettiBurst: Int = 0
    @Published var selectedTab: Tab = .now

    enum Tab: Hashable { case now, tasks, habits, timer }

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
        return open.first { $0.isFrog } ?? open.first
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
        reward(10, big: true)
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

    // MARK: - Persystencja (JSON w Documents)

    private struct Snapshot: Codable {
        var tasks: [TodoTask]
        var habits: [Habit]
        var xp: Int
    }

    private static var fileURL: URL {
        URL.documentsDirectory.appending(path: "ogarnito.json")
    }

    func save() {
        let snapshot = Snapshot(tasks: tasks, habits: habits, xp: xp)
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
    }
}
