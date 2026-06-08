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
        switch FeedMessageType(raw: rawJSON["type"]?.stringValue) {
        case .trigger:
            if let trigger = TriggerFeedItem(message: self) {
                return "Goldium · \(trigger.symbol) \(trigger.alertDirection.label)"
            }
        case .eodSummary:
            return "Goldium · End of Day Summary"
        case .unknown:
            break
        }

        if let symbol = rawJSON["symbol"]?.stringValue {
            return "Goldium · \(symbol)"
        }
        return "Goldium"
    }

    var notificationBody: String {
        switch FeedMessageType(raw: rawJSON["type"]?.stringValue) {
        case .trigger:
            if let trigger = TriggerFeedItem(message: self) {
                return "\(trigger.alertLabel) · \(GoldiumFormatters.currency(trigger.currentPrice)) (\(GoldiumFormatters.percent(trigger.stockChangePercent)))"
            }
        case .eodSummary:
            if let summary = EODSummaryFeedItem(message: self) {
                return "P&L \(GoldiumFormatters.currency(summary.todayPnL)) (\(GoldiumFormatters.percent(summary.todayPnLPercent))) · \(summary.stocks.count) stocks"
            }
        case .unknown:
            break
        }

        return displayFields
            .filter { $0.key != "id" && $0.key != "timestamp" }
            .prefix(3)
            .map { "\($0.key): \($0.value)" }
            .joined(separator: " · ")
    }
}
