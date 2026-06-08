import Foundation
import Combine

enum ConnectionMode: String, CaseIterable, Identifiable {
    case polling
    case websocket

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .polling: return "Poll every 5 seconds"
        case .websocket: return "WebSocket (persistent)"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var serverHost: String {
        didSet { UserDefaults.standard.set(serverHost, forKey: Keys.serverHost) }
    }

    @Published var serverPort: String {
        didSet { UserDefaults.standard.set(serverPort, forKey: Keys.serverPort) }
    }

    @Published var connectionMode: ConnectionMode {
        didSet { UserDefaults.standard.set(connectionMode.rawValue, forKey: Keys.connectionMode) }
    }

    @Published var useDummyData: Bool {
        didSet { UserDefaults.standard.set(useDummyData, forKey: Keys.useDummyData) }
    }

    var baseURL: URL {
        URL(string: "http://\(serverHost):\(serverPort)")!
    }

    var webSocketURL: URL {
        URL(string: "ws://\(serverHost):\(serverPort)/ws/messages")!
    }

    init() {
        let defaults = UserDefaults.standard
        serverHost = defaults.string(forKey: Keys.serverHost) ?? "192.168.1.100"
        serverPort = defaults.string(forKey: Keys.serverPort) ?? "8080"
        let modeRaw = defaults.string(forKey: Keys.connectionMode) ?? ConnectionMode.polling.rawValue
        connectionMode = ConnectionMode(rawValue: modeRaw) ?? .polling
        useDummyData = defaults.object(forKey: Keys.useDummyData) as? Bool ?? true
    }

    private enum Keys {
        static let serverHost = "serverHost"
        static let serverPort = "serverPort"
        static let connectionMode = "connectionMode"
        static let useDummyData = "useDummyData"
    }
}
