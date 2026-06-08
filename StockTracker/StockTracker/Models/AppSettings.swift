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
    @Published var serverBaseURL: String {
        didSet { UserDefaults.standard.set(serverBaseURL, forKey: Keys.serverBaseURL) }
    }

    @Published var connectionMode: ConnectionMode {
        didSet { UserDefaults.standard.set(connectionMode.rawValue, forKey: Keys.connectionMode) }
    }

    @Published var useDummyData: Bool {
        didSet { UserDefaults.standard.set(useDummyData, forKey: Keys.useDummyData) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    @Published var colorScheme: AppColorScheme {
        didSet { UserDefaults.standard.set(colorScheme.rawValue, forKey: Keys.colorScheme) }
    }

    var palette: GoldiumPalette {
        colorScheme == .light ? .light : .dark
    }

    var baseURL: URL {
        URL(string: normalizedServerBaseURL) ?? URL(string: "https://localhost")!
    }

    var webSocketURL: URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.scheme = baseURL.scheme == "https" ? "wss" : "ws"
        components.path = "/ws/messages"
        return components.url!
    }

    var isServerURLValid: Bool {
        Self.isValidServerURL(serverBaseURL)
    }

    private var normalizedServerBaseURL: String {
        serverBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    init() {
        let defaults = UserDefaults.standard
        let resolvedURL = Self.resolveServerURL(from: defaults)
        serverBaseURL = resolvedURL

        if defaults.string(forKey: Keys.serverBaseURL) != resolvedURL {
            defaults.set(resolvedURL, forKey: Keys.serverBaseURL)
        }

        let modeRaw = defaults.string(forKey: Keys.connectionMode) ?? ConnectionMode.websocket.rawValue
        connectionMode = ConnectionMode(rawValue: modeRaw) ?? .websocket
        useDummyData = defaults.object(forKey: Keys.useDummyData) as? Bool ?? false
        notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? false
        let schemeRaw = defaults.string(forKey: Keys.colorScheme) ?? AppColorScheme.light.rawValue
        colorScheme = AppColorScheme(rawValue: schemeRaw) ?? .light
    }

    func resetServerURLToDefault() {
        serverBaseURL = Self.defaultServerURL
    }

    private static let defaultServerURL = "https://srelay.onrender.com"

    private static func resolveServerURL(from defaults: UserDefaults) -> String {
        if let savedURL = defaults.string(forKey: Keys.serverBaseURL),
           isValidServerURL(savedURL) {
            return savedURL.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let legacyHost = defaults.string(forKey: Keys.legacyServerHost)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !legacyHost.isEmpty {
            let legacyPort = defaults.string(forKey: Keys.legacyServerPort) ?? "8080"
            let migrated = "http://\(legacyHost):\(legacyPort)"
            if isValidServerURL(migrated) {
                return migrated
            }
        }

        return defaultServerURL
    }

    static func isValidServerURL(_ urlString: String) -> Bool {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let host = url.host,
              !host.isEmpty,
              url.scheme == "http" || url.scheme == "https" else {
            return false
        }
        return true
    }

    private enum Keys {
        static let serverBaseURL = "serverBaseURL"
        static let legacyServerHost = "serverHost"
        static let legacyServerPort = "serverPort"
        static let connectionMode = "connectionMode"
        static let useDummyData = "useDummyData"
        static let notificationsEnabled = "notificationsEnabled"
        static let colorScheme = "colorScheme"
    }
}
