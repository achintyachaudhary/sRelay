import Foundation

enum FeedMessageType: String {
    case trigger
    case eodSummary = "eod_summary"
    case unknown

    init(raw: String?) {
        guard let raw else { self = .unknown; return }
        self = FeedMessageType(rawValue: raw) ?? .unknown
    }
}

enum AlertDirection: String {
    case above
    case below
    case up
    case down

    init(raw: String?) {
        guard let raw else { self = .up; return }
        self = AlertDirection(rawValue: raw) ?? .up
    }

    var isBullish: Bool {
        switch self {
        case .above, .up: return true
        case .below, .down: return false
        }
    }

    var label: String {
        switch self {
        case .above: return "Moved Above"
        case .below: return "Moved Below"
        case .up: return "Moving Up"
        case .down: return "Moving Down"
        }
    }
}

enum StockCloseStatus: String {
    case profit
    case loss
    case flat

    init(raw: String?) {
        guard let raw else { self = .flat; return }
        self = StockCloseStatus(rawValue: raw) ?? .flat
    }
}

struct TriggerFeedItem {
    let id: String
    let timestamp: String
    let symbol: String
    let stockName: String
    let currentPrice: Double
    let stockChangePercent: Double
    let industry: String
    let alertDirection: AlertDirection
    let threshold: Double?
    let alertLabel: String
    let niftyValue: Double
    let niftyChangePercent: Double

    init?(message: StockMessage) {
        guard FeedMessageType(raw: message.rawJSON["type"]?.stringValue) == .trigger else {
            return nil
        }

        id = message.id
        timestamp = message.rawJSON["timestamp"]?.stringValue ?? ""

        let stock = message.rawJSON["stock"]?.objectValue ?? [:]
        let alert = message.rawJSON["alert"]?.objectValue ?? [:]
        let nifty = message.rawJSON["nifty"]?.objectValue ?? [:]

        symbol = stock["symbol"]?.stringValue ?? message.rawJSON["symbol"]?.stringValue ?? "—"
        stockName = stock["name"]?.stringValue ?? symbol
        currentPrice = stock["current_price"]?.doubleValue
            ?? message.rawJSON["current_price"]?.doubleValue ?? 0
        stockChangePercent = stock["change_percent_today"]?.doubleValue
            ?? message.rawJSON["change_percent_today"]?.doubleValue ?? 0
        industry = stock["industry"]?.stringValue ?? message.rawJSON["industry"]?.stringValue ?? "—"

        alertDirection = AlertDirection(raw: alert["direction"]?.stringValue ?? message.rawJSON["alert_direction"]?.stringValue)
        threshold = alert["threshold"]?.doubleValue ?? message.rawJSON["threshold"]?.doubleValue
        alertLabel = alert["label"]?.stringValue
            ?? message.rawJSON["alert_label"]?.stringValue
            ?? "\(symbol) \(alertDirection.label)"

        niftyValue = nifty["value"]?.doubleValue ?? message.rawJSON["nifty_value"]?.doubleValue ?? 0
        niftyChangePercent = nifty["change_percent_today"]?.doubleValue
            ?? message.rawJSON["nifty_change_percent_today"]?.doubleValue ?? 0
    }
}

struct EODStockItem: Identifiable {
    let id: String
    let symbol: String
    let name: String
    let invested: Double
    let currentValue: Double
    let todayPnL: Double
    let todayPnLPercent: Double
    let status: StockCloseStatus

    init?(dict: [String: JSONValue], index: Int) {
        symbol = dict["symbol"]?.stringValue ?? "—"
        id = dict["symbol"]?.stringValue ?? "stock-\(index)"
        name = dict["name"]?.stringValue ?? symbol
        invested = dict["invested"]?.doubleValue ?? 0
        currentValue = dict["current_value"]?.doubleValue ?? 0
        todayPnL = dict["today_pnl"]?.doubleValue ?? 0
        todayPnLPercent = dict["today_pnl_percent"]?.doubleValue ?? 0
        status = StockCloseStatus(raw: dict["status"]?.stringValue)
    }
}

struct EODSummaryFeedItem {
    let id: String
    let timestamp: String
    let date: String
    let invested: Double
    let currentValue: Double
    let todayPnL: Double
    let todayPnLPercent: Double
    let stocks: [EODStockItem]

    init?(message: StockMessage) {
        guard FeedMessageType(raw: message.rawJSON["type"]?.stringValue) == .eodSummary else {
            return nil
        }

        id = message.id
        timestamp = message.rawJSON["timestamp"]?.stringValue ?? ""
        date = message.rawJSON["date"]?.stringValue ?? ""

        let portfolio = message.rawJSON["portfolio"]?.objectValue ?? [:]
        invested = portfolio["invested"]?.doubleValue ?? message.rawJSON["invested"]?.doubleValue ?? 0
        currentValue = portfolio["current_value"]?.doubleValue ?? message.rawJSON["current_value"]?.doubleValue ?? 0
        todayPnL = portfolio["today_pnl"]?.doubleValue ?? message.rawJSON["today_pnl"]?.doubleValue ?? 0
        todayPnLPercent = portfolio["today_pnl_percent"]?.doubleValue
            ?? message.rawJSON["today_pnl_percent"]?.doubleValue ?? 0

        if case .array(let items) = message.rawJSON["stocks"] {
            stocks = items.enumerated().compactMap { index, item in
                guard case .object(let dict) = item else { return nil }
                return EODStockItem(dict: dict, index: index)
            }
        } else {
            stocks = []
        }
    }
}

private extension JSONValue {
    var objectValue: [String: JSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }

    var doubleValue: Double? {
        switch self {
        case .double(let value): return value
        case .int(let value): return Double(value)
        case .string(let value): return Double(value)
        default: return nil
        }
    }
}
