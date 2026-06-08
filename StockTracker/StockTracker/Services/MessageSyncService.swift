import Foundation

protocol MessageSyncService: AnyObject {
    var onMessages: (([StockMessage]) -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    var onStatusChange: ((String) -> Void)? { get set }

    func start(lastMessageID: String?)
    func stop()
    func updateLastMessageID(_ id: String?)
}

enum MessageSyncServiceFactory {
    @MainActor
    static func make(settings: AppSettings) -> MessageSyncService {
        if settings.useDummyData {
            return DummyMessageService()
        }

        switch settings.connectionMode {
        case .polling:
            return PollingMessageService(baseURL: settings.baseURL)
        case .websocket:
            return WebSocketMessageService(url: settings.webSocketURL)
        }
    }
}
