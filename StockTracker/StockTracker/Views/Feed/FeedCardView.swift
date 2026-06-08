import SwiftUI

struct FeedCardView: View {
    let message: StockMessage
    var isNew: Bool = false

    @Environment(\.goldiumPalette) private var palette

    var body: some View {
        Group {
            if let trigger = TriggerFeedItem(message: message) {
                TriggerAlertCard(item: trigger, isNew: isNew)
            } else if let summary = EODSummaryFeedItem(message: message) {
                EODSummaryCard(item: summary, isNew: isNew)
            } else {
                legacyCard
            }
        }
    }

    private var legacyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(message.rawJSON["type"]?.stringValue ?? "Update")
                .font(.caption.weight(.bold))
                .foregroundStyle(palette.gold)
            ForEach(message.displayFields.filter { $0.key != "id" && $0.key != "type" }, id: \.key) { field in
                HStack {
                    Text(field.key)
                        .font(.caption)
                        .foregroundStyle(palette.secondaryText)
                    Spacer()
                    Text(field.value)
                        .font(.subheadline)
                        .foregroundStyle(palette.primaryText)
                }
            }
        }
        .padding(16)
        .background(palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .modifier(FeedAppearAnimation(isNew: isNew))
    }
}

struct FeedAppearAnimation: ViewModifier {
    let isNew: Bool
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : (isNew ? -12 : 0))
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: appeared)
            .onAppear {
                appeared = true
            }
    }
}
