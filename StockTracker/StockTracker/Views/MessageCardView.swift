import SwiftUI

struct MessageCardView: View {
    let message: StockMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(message.rawJSON["type"]?.stringValue ?? "message")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)

                Spacer()

                if let symbol = message.rawJSON["symbol"]?.stringValue {
                    Text(symbol)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                ForEach(message.displayFields, id: \.key) { field in
                    HStack(alignment: .top, spacing: 12) {
                        Text(field.key)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 110, alignment: .leading)

                        Text(field.value)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

#Preview {
    MessageCardView(message: StockMessage(id: "msg_001", rawJSON: [
        "id": .string("msg_001"),
        "type": .string("price_update"),
        "symbol": .string("RELIANCE"),
        "price": .double(2845.50)
    ]))
    .padding()
}
