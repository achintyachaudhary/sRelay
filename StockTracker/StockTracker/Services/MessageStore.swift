import Foundation

final class MessageStore {
    static let maxMessages = 500

    private let fileURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documents.appendingPathComponent("messages.json")
    }

    func load() -> [StockMessage] {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return []
        }

        do {
            let decoded = try JSONDecoder().decode([StockMessage].self, from: data)
            return decoded
        } catch {
            return []
        }
    }

    func save(_ messages: [StockMessage]) {
        let capped = messages.count > Self.maxMessages
            ? Array(messages.suffix(Self.maxMessages))
            : messages

        guard let data = try? JSONEncoder().encode(capped) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
