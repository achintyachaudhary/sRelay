import Foundation

final class WebSocketMessageService: MessageSyncService {
    var onMessages: (([StockMessage]) -> Void)?
    var onError: ((String) -> Void)?
    var onStatusChange: ((String) -> Void)?

    private let url: URL
    private var webSocketTask: URLSessionWebSocketTask?
    private var lastMessageID: String?
    private let session: URLSession

    private var isStopped = true
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 20
    private var reconnectWorkItem: DispatchWorkItem?

    init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    func start(lastMessageID: String?) {
        stop()
        isStopped = false
        self.lastMessageID = lastMessageID
        reconnectAttempts = 0
        connect()
    }

    func stop() {
        isStopped = true
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        onStatusChange?("Stopped")
    }

    func updateLastMessageID(_ id: String?) {
        lastMessageID = id
    }

    private func connect() {
        guard !isStopped else { return }

        onStatusChange?(reconnectAttempts == 0 ? "Connecting WebSocket…" : "Reconnecting WebSocket…")

        let task = session.webSocketTask(with: url)
        webSocketTask = task
        task.resume()

        sendSyncRequest()
        listen()
    }

    private func scheduleReconnect() {
        guard !isStopped else { return }

        reconnectAttempts += 1
        if reconnectAttempts > maxReconnectAttempts {
            onError?("WebSocket reconnect limit reached")
            onStatusChange?("WebSocket disconnected")
            return
        }

        let delay = min(pow(2.0, Double(reconnectAttempts - 1)), 60.0)
        onStatusChange?("Reconnecting in \(Int(delay))s…")

        let workItem = DispatchWorkItem { [weak self] in
            self?.connect()
        }
        reconnectWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
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
                self?.reconnectAttempts = 0
                self?.onStatusChange?("WebSocket connected")
            }
        }
    }

    private func sendPong() {
        guard let data = try? JSONSerialization.data(withJSONObject: ["action": "pong"]),
              let text = String(data: data, encoding: .utf8) else { return }

        webSocketTask?.send(.string(text)) { _ in }
    }

    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self, !self.isStopped else { return }

            switch result {
            case .failure(let error):
                self.onError?(error.localizedDescription)
                self.webSocketTask = nil
                self.scheduleReconnect()
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
            if envelope.type == "ping" {
                sendPong()
                return
            }
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
