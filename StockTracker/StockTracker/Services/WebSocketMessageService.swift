import Foundation

final class WebSocketMessageService: MessageSyncService {
    var onMessages: (([StockMessage]) -> Void)?
    var onError: ((String) -> Void)?
    var onStatusChange: ((String) -> Void)?

    private let url: URL
    private var webSocketTask: URLSessionWebSocketTask?
    private var lastMessageID: String?
    private let session: URLSession

    init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    func start(lastMessageID: String?) {
        stop()
        self.lastMessageID = lastMessageID
        onStatusChange?("Connecting WebSocket…")

        let task = session.webSocketTask(with: url)
        webSocketTask = task
        task.resume()

        sendSyncRequest()
        listen()
    }

    func stop() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        onStatusChange?("Stopped")
    }

    func updateLastMessageID(_ id: String?) {
        lastMessageID = id
        sendSyncRequest()
    }

    private func sendSyncRequest() {
        var payload: [String: Any] = ["action": "sync"]
        if let lastMessageID {
            payload["last_message_id"] = lastMessageID
        }

        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8) else { return }

        webSocketTask?.send(.string(text)) { [weak self] error in
            if let error {
                self?.onError?(error.localizedDescription)
            } else {
                self?.onStatusChange?("WebSocket connected")
            }
        }
    }

    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure(let error):
                self.onError?(error.localizedDescription)
            case .success(let message):
                self.handle(message)
                self.listen()
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        let text: String?
        switch message {
        case .string(let value): text = value
        case .data(let data): text = String(data: data, encoding: .utf8)
        @unknown default: text = nil
        }

        guard let text, let data = text.data(using: .utf8) else { return }

        if let envelope = try? JSONDecoder().decode(WebSocketEnvelope.self, from: data) {
            if envelope.type == "ping" { return }
            if let messages = envelope.messages, !messages.isEmpty {
                onMessages?(messages)
            }
            return
        }

        if let response = try? JSONDecoder().decode(MessagesResponse.self, from: data),
           !response.messages.isEmpty {
            onMessages?(response.messages)
        }
    }
}

private struct WebSocketEnvelope: Decodable {
    let type: String?
    let messages: [StockMessage]?
}
