import SwiftUI

struct EODSummaryCard: View {
    let item: EODSummaryFeedItem
    var isNew: Bool = false

    @Environment(\.goldiumPalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            portfolioSummary
            Divider().overlay(palette.divider)

            if !item.stocks.isEmpty {
                Text("Today's Positions")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryText)

                VStack(spacing: 10) {
                    ForEach(item.stocks) { stock in
                        stockRow(stock)
                    }
                }
            }
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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("End of Day Summary")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(palette.primaryText)
                Text(item.date.isEmpty ? "Portfolio close" : item.date)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
            }
            Spacer()
            Text("EOD")
                .font(.caption2.weight(.bold))
                .foregroundStyle(palette.gold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(palette.gold.opacity(0.12))
                .clipShape(Capsule())
        }
    }

    private var portfolioSummary: some View {
        VStack(spacing: 12) {
            HStack {
                metric(title: "Invested", value: GoldiumFormatters.currency(item.invested))
                Spacer()
                metric(title: "Current", value: GoldiumFormatters.currency(item.currentValue))
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's P&L")
                        .font(.caption)
                        .foregroundStyle(palette.secondaryText)
                    Text(GoldiumFormatters.currency(item.todayPnL))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(item.todayPnL >= 0 ? palette.profit : palette.loss)
                        .monospacedDigit()
                }
                Spacer()
                PercentChangeBadge(value: item.todayPnLPercent)
            }
            .padding(12)
            .background(item.todayPnL >= 0 ? palette.mutedProfit : palette.mutedLoss)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(palette.secondaryText)
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.primaryText)
                .monospacedDigit()
        }
    }

    private func stockRow(_ stock: EODStockItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.primaryText)
                Text(stock.name)
                    .font(.caption2)
                    .foregroundStyle(palette.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(GoldiumFormatters.currency(stock.todayPnL))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(stock.status == .profit ? palette.profit : (stock.status == .loss ? palette.loss : palette.secondaryText))
                HStack(spacing: 6) {
                    PercentChangeBadge(value: stock.todayPnLPercent, compact: true)
                    statusChip(stock.status)
                }
            }
        }
        .padding(10)
        .background(palette.background)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func statusChip(_ status: StockCloseStatus) -> some View {
        Text(status == .profit ? "Profit" : (status == .loss ? "Loss" : "Flat"))
            .font(.caption2.weight(.bold))
            .foregroundStyle(status == .profit ? palette.profit : (status == .loss ? palette.loss : palette.secondaryText))
    }
}
