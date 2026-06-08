import Foundation

final class DummyMessageService: MessageSyncService {
    var onMessages: (([StockMessage]) -> Void)?
    var onError: ((String) -> Void)?
    var onStatusChange: ((String) -> Void)?

    private var timer: Timer?
    private var lastMessageID: String?
    private var messageCounter = 0

    private let seedMessages: [StockMessage] = [
        StockMessage(id: "msg_001", rawJSON: [
            "id": .string("msg_001"),
            "timestamp": .string("2025-06-08T09:30:00Z"),
            "type": .string("price_update"),
            "symbol": .string("RELIANCE"),
            "price": .double(2845.50),
            "change_percent": .double(1.25),
            "volume": .int(1_250_000)
        ]),
        StockMessage(id: "msg_002", rawJSON: [
            "id": .string("msg_002"),
            "timestamp": .string("2025-06-08T09:31:00Z"),
            "type": .string("price_update"),
            "symbol": .string("TCS"),
            "price": .double(3842.75),
            "change_percent": .double(-0.45),
            "volume": .int(890_000)
        ]),
        StockMessage(id: "msg_003", rawJSON: [
            "id": .string("msg_003"),
            "timestamp": .string("2025-06-08T09:32:00Z"),
            "type": .string("alert"),
            "symbol": .string("INFY"),
            "message": .string("Volume spike detected — 3x average"),
            "severity": .string("medium")
        ])
    ]

    func start(lastMessageID: String?) {
        stop()
        self.lastMessageID = lastMessageID
        onStatusChange?("Dummy mode — simulating server")

        if lastMessageID == nil {
            onMessages?(seedMessages)
        }

        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.emitNextMessage()
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

    private func emitNextMessage() {
        messageCounter += 1
        let id = String(format: "msg_%03d", 3 + messageCounter)
        let symbols = ["HDFCBANK", "ICICIBANK", "SBIN", "BAJFINANCE", "WIPRO"]
        let symbol = symbols[messageCounter % symbols.count]
        let price = Double.random(in: 500...4500)
        let change = Double.random(in: -3.0...3.0)

        let message = StockMessage(id: id, rawJSON: [
            "id": .string(id),
            "timestamp": .string(ISO8601DateFormatter().string(from: Date())),
            "type": .string(messageCounter % 3 == 0 ? "alert" : "price_update"),
            "symbol": .string(symbol),
            "price": .double(price),
            "change_percent": .double(change),
            "volume": .int(Int.random(in: 100_000...2_000_000)),
            "note": .string("Dummy data — replace with live BE")
        ])

        onMessages?([message])
    }
}
