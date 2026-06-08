import Foundation
import Combine

@MainActor
final class MessageFeedViewModel: ObservableObject {
    @Published private(set) var messages: [StockMessage] = []
    @Published private(set) var statusText = "Idle"
    @Published private(set) var lastError: String?
    @Published private(set) var isRunning = false

    private var service: MessageSyncService?
    private var settings: AppSettings?

    var lastMessageID: String? {
        messages.last?.id
    }

    func configure(settings: AppSettings) {
        self.settings = settings
    }

    func start() {
        guard let settings else { return }
        stop()

        let service = MessageSyncServiceFactory.make(settings: settings)
        self.service = service

        service.onMessages = { [weak self] newMessages in
            Task { @MainActor in
                self?.appendMessages(newMessages)
            }
        }
        service.onError = { [weak self] error in
            Task { @MainActor in
                self?.lastError = error
            }
        }
        service.onStatusChange = { [weak self] status in
            Task { @MainActor in
                self?.statusText = status
            }
        }

        service.start(lastMessageID: lastMessageID)
        isRunning = true
        lastError = nil
    }

    func stop() {
        service?.stop()
        service = nil
        isRunning = false
        statusText = "Stopped"
    }

    func restart() {
        stop()
        start()
    }

    func clearMessages() {
        messages = []
        service?.updateLastMessageID(nil)
    }

    private func appendMessages(_ incoming: [StockMessage]) {
        let existingIDs = Set(messages.map(\.id))
        let unique = incoming.filter { !existingIDs.contains($0.id) }
        guard !unique.isEmpty else { return }

        messages.append(contentsOf: unique)
        service?.updateLastMessageID(messages.last?.id)
        lastError = nil
    }
}
