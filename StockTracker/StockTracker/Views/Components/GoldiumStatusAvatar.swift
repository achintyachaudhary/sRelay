import SwiftUI

struct GoldiumStatusAvatar: View {
    let isConnected: Bool
    var size: CGFloat = 34

    @Environment(\.goldiumPalette) private var palette

    private var ringColor: Color {
        isConnected ? palette.profit : palette.loss
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.30 + 4, style: .continuous)
                .strokeBorder(ringColor, lineWidth: 2.5)
                .frame(width: size + 8, height: size + 8)

            GoldiumLogo(size: size)
        }
        .accessibilityLabel(isConnected ? "Goldium connected — open settings" : "Goldium offline — open settings")
    }
}
