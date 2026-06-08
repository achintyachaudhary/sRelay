import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func notify(for message: StockMessage) {
        let content = UNMutableNotificationContent()
        content.title = message.notificationTitle
        content.body = message.notificationBody
        content.sound = .default
        content.userInfo = ["messageId": message.id]

        let request = UNNotificationRequest(
            identifier: "stock-\(message.id)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}

private extension StockMessage {
    var notificationTitle: String {
        if let symbol = rawJSON["symbol"]?.stringValue {
            let type = rawJSON["type"]?.stringValue ?? "update"
            return "\(symbol) · \(type.replacingOccurrences(of: "_", with: " "))"
        }
        return rawJSON["type"]?.stringValue?
            .replacingOccurrences(of: "_", with: " ")
            .capitalized ?? "Stock Tracker"
    }

    var notificationBody: String {
        if let text = rawJSON["message"]?.stringValue {
            return text
        }

        if let price = rawJSON["price"] {
            var parts = ["Price: \(price.displayString)"]
            if let change = rawJSON["change_percent"] {
                parts.append("Change: \(change.displayString)%")
            }
            return parts.joined(separator: " · ")
        }

        return displayFields
            .filter { $0.key != "id" && $0.key != "timestamp" }
            .prefix(3)
            .map { "\($0.key): \($0.value)" }
            .joined(separator: " · ")
    }
}
