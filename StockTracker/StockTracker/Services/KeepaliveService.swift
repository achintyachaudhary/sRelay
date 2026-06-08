import Foundation

final class KeepaliveService {
    static let interval: TimeInterval = 420

    var onStatusChange: ((String) -> Void)?

    private var timer: Timer?
    private var baseURL: URL?
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func start(baseURL: URL) {
        stop()
        self.baseURL = baseURL
        onStatusChange?("Keepalive starting…")

        ping()
        timer = Timer.scheduledTimer(withTimeInterval: Self.interval, repeats: true) { [weak self] _ in
            self?.ping()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        baseURL = nil
        onStatusChange?("Keepalive stopped")
    }

    private func ping() {
        guard let baseURL else { return }

        let url = baseURL.appendingPathComponent("health")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        session.dataTask(with: request) { [weak self] data, response, error in
            if let error {
                self?.onStatusChange?("Keepalive failed: \(error.localizedDescription)")
                return
            }

            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                self?.onStatusChange?("Keepalive failed: HTTP \(code)")
                return
            }

            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let time = formatter.string(from: Date())
            self?.onStatusChange?("Keepalive OK · \(time)")
        }.resume()
    }
}
