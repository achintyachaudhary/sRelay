import SwiftUI

struct GoldiumLogo: View {
    var size: CGFloat = 28

    @Environment(\.goldiumPalette) private var palette

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [palette.gold, palette.gold.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Text("G")
                .font(.system(size: size * 0.52, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .accessibilityLabel("Goldium")
    }
}

struct GoldiumWordmark: View {
    @Environment(\.goldiumPalette) private var palette

    var body: some View {
        HStack(spacing: 8) {
            GoldiumLogo(size: 30)
            Text("Goldium")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.primaryText)
        }
    }
}
