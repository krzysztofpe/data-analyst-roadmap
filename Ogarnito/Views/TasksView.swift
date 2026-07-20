import SwiftUI

/// Zadania + brain dump: wrzucasz wszystko z głowy bez oceniania,
/// potem rozbijasz nożem na mikro-kroki.
struct TasksView: View {
    @EnvironmentObject var store: AppStore
    @State private var dumpText = ""
    @State private var expandedTasks: Set<TodoTask.ID> = []
    @FocusState private var dumpFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                brainDump

                if store.tasks.isEmpty {
                    VStack(spacing: 8) {
                        Text("🧘").font(.system(size: 40))
                        Text("Pusto! Wrzuć wyżej wszystko, co chodzi Ci po głowie.")
                            .font(.subheadline)
                            .foregroundColor(.appMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 30)
                } else {
                    ForEach(store.sortedTasks) { task in
                        TaskCard(
                            task: task,
                            isExpanded: expandedTasks.contains(task.id),
                            onToggleExpand: {
                                if expandedTasks.contains(task.id) {
                                    expandedTasks.remove(task.id)
                                } else {
                                    expandedTasks.insert(task.id)
                                }
                            }
                        )
                    }
                }
            }
            .padding(16)
        }
        .background(AppBackground())
        .scrollDismissesKeyboard(.interactively)
    }

    private var brainDump: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Wrzuć, co masz w głowie…", text: $dumpText)
                    .focused($dumpFocused)
                    .submitLabel(.done)
                    .onSubmit(addFromDump)
                    .padding(13)
                    .background(Color.appCard, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(
                        dumpFocused ? Color.appAccent : Color.appLine))

                Button(action: addFromDump) {
                    Image(systemName: "plus")
                        .font(.title3.bold())
                        .frame(width: 50, height: 50)
                        .background(Color.appAccentDark, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundColor(.white)
                }
            }
            Text("🧠 Brain dump: nie planuj, nie oceniaj — po prostu wypisz wszystko z głowy. Ogarniesz to potem.")
                .font(.caption)
                .foregroundColor(.appMuted)
        }
    }

    private func addFromDump() {
        store.addTask(dumpText)
        dumpText = ""
        dumpFocused = true
    }
}

struct TaskCard: View {
    @EnvironmentObject var store: AppStore
    let task: TodoTask
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    @State private var newStepText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 11) {
                CheckCircle(done: task.done, size: 28) {
                    store.toggleTask(task.id)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .strikethrough(task.done)
                        .foregroundColor(task.done ? .appMuted : .white)
                    HStack(spacing: 6) {
                        if task.isFrog {
                            Badge(text: "🐸 żaba", color: .appFrog)
                        }
                        if !task.steps.isEmpty {
                            Badge(text: "\(task.doneStepsCount)/\(task.steps.count) kroków",
                                  color: .appMuted)
                        }
                    }
                }

                Spacer()

                Menu {
                    Button {
                        store.toggleFrog(task.id)
                    } label: {
                        Label(task.isFrog ? "Odbierz żabę" : "Najważniejsze dziś 🐸",
                              systemImage: "star")
                    }
                    Button(action: onToggleExpand) {
                        Label("Rozbij na kroki 🔪", systemImage: "scissors")
                    }
                    Button(role: .destructive) {
                        store.deleteTask(task.id)
                    } label: {
                        Label("Usuń", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 34, height: 34)
                        .background(Color.appCard2, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.appMuted)
                }
            }

            if isExpanded || !task.steps.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(task.steps) { step in
                        HStack(spacing: 9) {
                            CheckCircle(done: step.done, size: 21) {
                                store.toggleStep(taskID: task.id, stepID: step.id)
                            }
                            Text(step.text)
                                .font(.subheadline)
                                .strikethrough(step.done)
                                .foregroundColor(step.done ? .appMuted : .white)
                        }
                    }

                    if isExpanded {
                        HStack(spacing: 8) {
                            TextField("Mały krok (max 10 min)…", text: $newStepText)
                                .font(.subheadline)
                                .submitLabel(.done)
                                .onSubmit(addStep)
                                .padding(9)
                                .background(Color.appCard2, in: RoundedRectangle(cornerRadius: 10))
                            Button(action: addStep) {
                                Image(systemName: "plus")
                                    .frame(width: 36, height: 36)
                                    .background(Color.appCard2, in: RoundedRectangle(cornerRadius: 10))
                                    .foregroundColor(.appAccent)
                            }
                        }
                    }
                }
                .padding(.leading, 39)
            }
        }
        .padding(13)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(
            task.isFrog ? Color.appFrog : Color.appLine))
    }

    private func addStep() {
        store.addStep(taskID: task.id, text: newStepText)
        newStepText = ""
    }
}

struct CheckCircle: View {
    let done: Bool
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(done ? Color.appGood : Color.appMuted, lineWidth: 2)
                    .background(Circle().fill(done ? Color.appGood : Color.clear))
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.45, weight: .bold))
                        .foregroundColor(Color(hex: 0x06281C))
                }
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }
}

struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.appCard2, in: RoundedRectangle(cornerRadius: 8))
    }
}
