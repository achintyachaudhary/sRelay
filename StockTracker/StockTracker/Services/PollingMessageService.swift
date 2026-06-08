import Foundation

final class PollingMessageService: MessageSyncService {
    var onMessages: (([StockMessage]) -> Void)?
    var onError: ((String) -> Void)?
    var onStatusChange: ((String) -> Void)?

    private let baseURL: URL
    private var timer: Timer?
    private var lastMessageID: String?
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func start(lastMessageID: String?) {
        stop()
        self.lastMessageID = lastMessageID
        onStatusChange?("Polling every 5s")

        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        onStatusChange?("Stopped")
    }

    func updateLastMessageID(_ id: String?) {
        lastMessageID = id
    }

    private func poll() {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/v1/messages"), resolvingAgainstBaseURL: false)!
        if let lastMessageID {
            components.queryItems = [URLQueryItem(name: "since_id", value: lastMessageID)]
        }

        guard let url = components.url else {
            onError?("Invalid polling URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        session.dataTask(with: request) { [weak self] data, response, error in
            if let error {
                self?.onError?(error.localizedDescription)
                return
            }

            guard let http = response as? HTTPURLResponse else {
                self?.onError?("Invalid server response")
                return
            }

            guard (200...299).contains(http.statusCode), let data else {
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                self?.onError?("HTTP \(http.statusCode): \(body)")
                return
            }

            do {
                let decoded = try JSONDecoder().decode(MessagesResponse.self, from: data)
                if !decoded.messages.isEmpty {
                    self?.onMessages?(decoded.messages)
                }
            } catch {
                self?.onError?("Decode error: \(error.localizedDescription)")
            }
        }.resume()
    }
}
