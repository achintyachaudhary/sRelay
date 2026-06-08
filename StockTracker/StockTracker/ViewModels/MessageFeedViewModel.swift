import Foundation
import Combine

@MainActor
final class MessageFeedViewModel: ObservableObject {
    @Published private(set) var messages: [StockMessage] = []
    @Published private(set) var statusText = "Idle"
    @Published private(set) var lastError: String?
    @Published private(set) var isRunning = false
    @Published private(set) var keepaliveStatus = "Keepalive idle"
    @Published private(set) var newlyArrivedIDs: Set<String> = []

    private var service: MessageSyncService?
    private var settings: AppSettings?
    private var skipNotificationsForNextBatch = true
    private let messageStore = MessageStore()
    private let keepaliveService = KeepaliveService()

    var lastMessageID: String? {
        FeedOrdering.latestMessageID(in: messages)
    }

    var isServerConnected: Bool {
        guard isRunning else { return false }
        let status = statusText.lowercased()
        return status.contains("connected") || status.contains("dummy feed")
    }

    func configure(settings: AppSettings) {
        self.settings = settings

        keepaliveService.onStatusChange = { [weak self] status in
            Task { @MainActor in
                self?.keepaliveStatus = status
            }
        }

        let persisted = messageStore.load()
        if !persisted.isEmpty {
            messages = FeedOrdering.sort(persisted)
        }
    }

    func start() {
        guard let settings else { return }
        stop()

        if !settings.useDummyData {
            keepaliveService.start(baseURL: settings.baseURL)
        }

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

        skipNotificationsForNextBatch = true
        service.start(lastMessageID: lastMessageID)
        isRunning = true
        lastError = nil
    }

    func stop() {
        keepaliveService.stop()
        service?.stop()
        service = nil
        isRunning = false
        statusText = "Stopped"
        keepaliveStatus = "Keepalive stopped"
    }

    func restart() {
        stop()
        start()
    }

    func clearMessages() {
        messages = []
        newlyArrivedIDs = []
        messageStore.clear()
        service?.updateLastMessageID(nil)
    }

    func deleteMessage(id: String) {
        messages.removeAll { $0.id == id }
        newlyArrivedIDs.remove(id)
        messageStore.save(messages)
        service?.updateLastMessageID(lastMessageID)
    }

    func isNewMessage(_ id: String) -> Bool {
        newlyArrivedIDs.contains(id)
    }

    private func appendMessages(_ incoming: [StockMessage]) {
        let existingIDs = Set(messages.map(\.id))
        let unique = incoming.filter { !existingIDs.contains($0.id) }
        guard !unique.isEmpty else { return }

        let shouldNotify = settings?.notificationsEnabled == true && !skipNotificationsForNextBatch
        skipNotificationsForNextBatch = false

        messages.append(contentsOf: unique)
        messages = FeedOrdering.sort(messages)
        newlyArrivedIDs.formUnion(unique.map(\.id))

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            newlyArrivedIDs.subtract(unique.map(\.id))
        }

        messageStore.save(messages)
        service?.updateLastMessageID(lastMessageID)
        lastError = nil

        if shouldNotify {
            for message in unique {
                NotificationService.shared.notify(for: message)
            }
        }
    }

}
