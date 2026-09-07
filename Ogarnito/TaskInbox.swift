import Foundation

/// Skrzynka odbiorcza dla zadań łapanych spoza aplikacji (Siri, Skróty).
/// Osobny plik, żeby zapis z tła nigdy nie ścigał się o dane z działającą
/// aplikacją — Ogarnito zabiera je stąd przy najbliższym otwarciu.
enum TaskInbox {
    private static var url: URL {
        URL.documentsDirectory.appending(path: "inbox.json")
    }

    static func append(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var items = read()
        items.append(trimmed)
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// Zwraca wszystko, co czekało, i czyści skrzynkę.
    static func drain() -> [String] {
        let items = read()
        guard !items.isEmpty else { return [] }
        try? FileManager.default.removeItem(at: url)
        return items
    }

    private static func read() -> [String] {
        guard let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return items
    }
}
