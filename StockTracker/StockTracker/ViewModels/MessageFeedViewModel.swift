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
        messages.first?.id
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
            messages = sortNewestFirst(persisted)
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
                self?.syncLiveActivity(status: status)
            }
        }

        skipNotificationsForNextBatch = true
        service.start(lastMessageID: lastMessageID)
        isRunning = true
        lastError = nil
        syncLiveActivity(status: statusText)
    }

    func stop() {
        keepaliveService.stop()
        service?.stop()
        service = nil
        isRunning = false
        statusText = "Stopped"
        keepaliveStatus = "Keepalive stopped"
        LiveActivityService.shared.update(isLive: false, status: "Disconnected")
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

    func isNewMessage(_ id: String) -> Bool {
        newlyArrivedIDs.contains(id)
    }

    private func appendMessages(_ incoming: [StockMessage]) {
        let existingIDs = Set(messages.map(\.id))
        let unique = incoming.filter { !existingIDs.contains($0.id) }
        guard !unique.isEmpty else { return }

        let shouldNotify = settings?.notificationsEnabled == true && !skipNotificationsForNextBatch
        skipNotificationsForNextBatch = false

        for message in unique.reversed() {
            messages.insert(message, at: 0)
        }
        newlyArrivedIDs.formUnion(unique.map(\.id))

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            newlyArrivedIDs.subtract(unique.map(\.id))
        }

        messageStore.save(sortNewestFirst(messages))
        service?.updateLastMessageID(messages.first?.id)
        lastError = nil

        if shouldNotify {
            for message in unique {
                NotificationService.shared.notify(for: message)
            }
        }
    }

    private func syncLiveActivity(status: String) {
        let isConnected = status.lowercased().contains("connected") || status.lowercased().contains("dummy feed")
        LiveActivityService.shared.update(isLive: isConnected && isRunning, status: status)
    }

    private func sortNewestFirst(_ items: [StockMessage]) -> [StockMessage] {
        items.sorted { lhs, rhs in
            let left = lhs.rawJSON["timestamp"]?.stringValue ?? lhs.id
            let right = rhs.rawJSON["timestamp"]?.stringValue ?? rhs.id
            return left > right
        }
    }
}
