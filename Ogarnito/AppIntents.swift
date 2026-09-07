import AppIntents

/// „Hej Siri, dodaj zadanie do Ogarnito" — myśl złapana w dwie sekundy,
/// bez odblokowywania telefonu i bez szukania aplikacji. Dla ADHD-mózgu
/// różnica między złapaną a utraconą myślą to często cały dzień roboty.
struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Dodaj zadanie"
    static var description = IntentDescription(
        "Wrzuca zadanie do Ogarnito, zanim zdążysz o nim zapomnieć."
    )
    /// Nie otwieramy aplikacji — chodzi o to, żeby nie wypaść z tego, co robisz.
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Zadanie", requestValueDialog: "Co masz w głowie?")
    var taskTitle: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        TaskInbox.append(taskTitle)
        return .result(dialog: "Zapisane. Głowa wolna 🧠")
    }
}

/// „Hej Siri, przerwij scroll" — wywołasz to, siedząc w reelsach, bez szukania
/// aplikacji. Właśnie wtedy jest potrzebne, a nie wtedy, gdy już tu jesteś.
struct StopScrollIntent: AppIntent {
    static var title: LocalizedStringResource = "Przerwij scrollowanie"
    static var description = IntentDescription(
        "Otwiera Ogarnito na ekranie przerwania scrolla: oddech i pytanie, czego naprawdę teraz potrzebujesz."
    )
    /// Tutaj otwarcie apki jest sensem działania — chodzi o wyrwanie z pętli.
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(true, forKey: "pendingScreenBreak")
        return .result()
    }
}

struct OgarnitoShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Dodaj zadanie do \(.applicationName)",
                "Zapisz w \(.applicationName)",
                "Nowe zadanie w \(.applicationName)"
            ],
            shortTitle: "Dodaj zadanie",
            systemImageName: "plus.circle.fill"
        )
        AppShortcut(
            intent: StopScrollIntent(),
            phrases: [
                "Przerwij scroll w \(.applicationName)",
                "Przyłapałem się w \(.applicationName)",
                "Stop scroll w \(.applicationName)"
            ],
            shortTitle: "Przerwij scrollowanie",
            systemImageName: "hand.raised.fill"
        )
    }
}
