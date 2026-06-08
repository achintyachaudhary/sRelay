import SwiftUI

enum AppColorScheme: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var swiftUIColorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct GoldiumPalette {
    let background: Color
    let card: Color
    let cardBorder: Color
    let primaryText: Color
    let secondaryText: Color
    let divider: Color
    let gold: Color
    let profit: Color
    let loss: Color
    let mutedProfit: Color
    let mutedLoss: Color
    let headerBackground: Color

    static let light = GoldiumPalette(
        background: Color(red: 0.98, green: 0.98, blue: 0.99),
        card: .white,
        cardBorder: Color.black.opacity(0.06),
        primaryText: Color(red: 0.09, green: 0.09, blue: 0.11),
        secondaryText: Color(red: 0.45, green: 0.45, blue: 0.50),
        divider: Color.black.opacity(0.08),
        gold: Color(red: 0.79, green: 0.64, blue: 0.15),
        profit: Color(red: 0.12, green: 0.59, blue: 0.36),
        loss: Color(red: 0.84, green: 0.24, blue: 0.24),
        mutedProfit: Color(red: 0.12, green: 0.59, blue: 0.36).opacity(0.12),
        mutedLoss: Color(red: 0.84, green: 0.24, blue: 0.24).opacity(0.12),
        headerBackground: .white
    )

    static let dark = GoldiumPalette(
        background: Color(red: 0.05, green: 0.05, blue: 0.06),
        card: Color(red: 0.11, green: 0.11, blue: 0.12),
        cardBorder: Color.white.opacity(0.08),
        primaryText: Color(red: 0.95, green: 0.95, blue: 0.97),
        secondaryText: Color(red: 0.62, green: 0.62, blue: 0.66),
        divider: Color.white.opacity(0.08),
        gold: Color(red: 0.85, green: 0.70, blue: 0.25),
        profit: Color(red: 0.30, green: 0.78, blue: 0.55),
        loss: Color(red: 0.95, green: 0.40, blue: 0.40),
        mutedProfit: Color(red: 0.30, green: 0.78, blue: 0.55).opacity(0.15),
        mutedLoss: Color(red: 0.95, green: 0.40, blue: 0.40).opacity(0.15),
        headerBackground: Color(red: 0.08, green: 0.08, blue: 0.09)
    )
}

private struct GoldiumPaletteKey: EnvironmentKey {
    static let defaultValue = GoldiumPalette.light
}

extension EnvironmentValues {
    var goldiumPalette: GoldiumPalette {
        get { self[GoldiumPaletteKey.self] }
        set { self[GoldiumPaletteKey.self] = newValue }
    }
}

struct GoldiumFormatters {
    static func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = value >= 1000 ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "₹\(value)"
    }

    static func percent(_ value: Double, signed: Bool = true) -> String {
        let prefix = signed && value > 0 ? "+" : ""
        return String(format: "%@%.2f%%", prefix, value)
    }

    static func time(_ iso: String) -> String {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = parser.date(from: iso)
        if date == nil {
            parser.formatOptions = [.withInternetDateTime]
            date = parser.date(from: iso)
        }
        guard let date else { return "" }
        let display = DateFormatter()
        display.timeStyle = .short
        return display.string(from: date)
    }
}
