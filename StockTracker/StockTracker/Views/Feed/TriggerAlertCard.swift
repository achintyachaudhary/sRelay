import SwiftUI

struct TriggerAlertCard: View {
    let item: TriggerFeedItem
    var isNew: Bool = false

    @Environment(\.goldiumPalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            alertBanner
            stockRow
            Divider().overlay(palette.divider)
            niftyRow
        }
        .padding(16)
        .background(palette.card)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 3)
        .modifier(FeedAppearAnimation(isNew: isNew))
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.stockName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(palette.primaryText)
                Text(item.symbol)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(palette.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("TRIGGER")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(palette.gold)
                if !item.timestamp.isEmpty {
                    Text(GoldiumFormatters.time(item.timestamp))
                        .font(.caption2)
                        .foregroundStyle(palette.secondaryText)
                }
            }
        }
    }

    private var alertBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: item.alertDirection.isBullish ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                .font(.title3)
                .foregroundStyle(item.alertDirection.isBullish ? palette.profit : palette.loss)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.alertLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.primaryText)
                if let threshold = item.threshold {
                    Text("Threshold: \(GoldiumFormatters.currency(threshold))")
                        .font(.caption)
                        .foregroundStyle(palette.secondaryText)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(item.alertDirection.isBullish ? palette.mutedProfit : palette.mutedLoss)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var stockRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Stock")
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
                PriceText(value: item.currentPrice, fontSize: 20)
                Text(item.industry)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
                PercentChangeBadge(value: item.stockChangePercent)
            }
        }
    }

    private var niftyRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("NIFTY 50")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryText)
                PriceText(value: item.niftyValue, fontSize: 16)
            }

            Spacer()

            PercentChangeBadge(value: item.niftyChangePercent, compact: true)
        }
    }
}
