import Foundation

final class DummyMessageService: MessageSyncService {
    var onMessages: (([StockMessage]) -> Void)?
    var onError: ((String) -> Void)?
    var onStatusChange: ((String) -> Void)?

    private var timer: Timer?
    private var messageCounter = 0

    private let seedMessages: [StockMessage] = [
        makeTrigger(
            id: "msg_001",
            symbol: "RELIANCE",
            name: "Reliance Industries",
            price: 2845.50,
            change: 1.25,
            direction: "above",
            threshold: 2800,
            industry: "Oil & Gas"
        ),
        makeTrigger(
            id: "msg_002",
            symbol: "TCS",
            name: "Tata Consultancy Services",
            price: 642.30,
            change: -1.85,
            direction: "below",
            threshold: 650,
            industry: "IT Services"
        ),
        makeEODSummary(id: "msg_003")
    ]

    func start(lastMessageID: String?) {
        stop()
        onStatusChange?("Dummy feed — simulating live socket")

        if lastMessageID == nil {
            onMessages?(seedMessages)
        }

        timer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            self?.emitNextMessage()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        onStatusChange?("Stopped")
    }

    func updateLastMessageID(_ id: String?) {}

    private func emitNextMessage() {
        messageCounter += 1
        let id = String(format: "msg_%03d", 3 + messageCounter)

        let message: StockMessage
        if messageCounter % 5 == 0 {
            message = makeEODSummary(id: id)
        } else {
            let symbols = ["HDFCBANK", "ICICIBANK", "INFY", "SBIN", "WIPRO"]
            let symbol = symbols[messageCounter % symbols.count]
            let price = Double.random(in: 400...3500)
            let change = Double.random(in: -2.5...2.5)
            let above = change >= 0
            message = makeTrigger(
                id: id,
                symbol: symbol,
                name: symbol,
                price: price,
                change: change,
                direction: above ? "above" : "below",
                threshold: above ? price - 50 : price + 50,
                industry: "Financials"
            )
        }

        onMessages?([message])
    }

    private static func makeTrigger(
        id: String,
        symbol: String,
        name: String,
        price: Double,
        change: Double,
        direction: String,
        threshold: Double,
        industry: String
    ) -> StockMessage {
        StockMessage(id: id, rawJSON: [
            "id": .string(id),
            "type": .string("trigger"),
            "timestamp": .string(ISO8601DateFormatter().string(from: Date())),
            "stock": .object([
                "symbol": .string(symbol),
                "name": .string(name),
                "current_price": .double(price),
                "change_percent_today": .double(change),
                "industry": .string(industry)
            ]),
            "alert": .object([
                "direction": .string(direction),
                "threshold": .double(threshold),
                "label": .string("\(symbol) moved \(direction) \(Int(threshold))")
            ]),
            "nifty": .object([
                "value": .double(23_542.30),
                "change_percent_today": .double(0.38)
            ])
        ])
    }

    private static func makeEODSummary(id: String) -> StockMessage {
        StockMessage(id: id, rawJSON: [
            "id": .string(id),
            "type": .string("eod_summary"),
            "timestamp": .string(ISO8601DateFormatter().string(from: Date())),
            "date": .string("Today"),
            "portfolio": .object([
                "invested": .double(850_000),
                "current_value": .double(872_450),
                "today_pnl": .double(4_820),
                "today_pnl_percent": .double(0.56)
            ]),
            "stocks": .array([
                .object([
                    "symbol": .string("RELIANCE"),
                    "name": .string("Reliance Industries"),
                    "invested": .double(200_000),
                    "current_value": .double(208_500),
                    "today_pnl": .double(2_100),
                    "today_pnl_percent": .double(1.02),
                    "status": .string("profit")
                ]),
                .object([
                    "symbol": .string("TCS"),
                    "name": .string("TCS"),
                    "invested": .double(150_000),
                    "current_value": .double(147_200),
                    "today_pnl": .double(-980),
                    "today_pnl_percent": .double(-0.66),
                    "status": .string("loss")
                ]),
                .object([
                    "symbol": .string("INFY"),
                    "name": .string("Infosys"),
                    "invested": .double(120_000),
                    "current_value": .double(121_050),
                    "today_pnl": .double(320),
                    "today_pnl_percent": .double(0.26),
                    "status": .string("profit")
                ])
            ])
        ])
    }
}
