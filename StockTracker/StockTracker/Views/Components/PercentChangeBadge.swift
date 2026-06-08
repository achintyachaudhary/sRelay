import SwiftUI

struct PercentChangeBadge: View {
    let value: Double
    var compact: Bool = false

    @Environment(\.goldiumPalette) private var palette

    private var isPositive: Bool { value >= 0 }

    var body: some View {
        Text(GoldiumFormatters.percent(value))
            .font(.system(size: compact ? 12 : 13, weight: .semibold, design: .rounded))
            .foregroundStyle(isPositive ? palette.profit : palette.loss)
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 4 : 5)
            .background(isPositive ? palette.mutedProfit : palette.mutedLoss)
            .clipShape(Capsule())
    }
}

struct PriceText: View {
    let value: Double
    var fontSize: CGFloat = 22

    @Environment(\.goldiumPalette) private var palette

    var body: some View {
        Text(GoldiumFormatters.currency(value))
            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
            .foregroundStyle(palette.primaryText)
            .monospacedDigit()
    }
}
