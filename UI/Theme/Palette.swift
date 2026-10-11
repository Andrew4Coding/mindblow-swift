import SwiftUI
import UIKit

enum Palette {
    static let cream = Color(light: 0xFAF8F0, dark: 0x1F1E26)
    static let card = Color(light: 0xFFFFFF, dark: 0x2D2C36)
    static let softCard = Color(light: 0xEFEDE4, dark: 0x3A3945)
    static let ink = Color(light: 0x2B2A33, dark: 0xF2EFE6)
    static let onAccent = Color(light: 0x2B2A33, dark: 0x2B2A33)

    static let mint = Color(light: 0x5ED3A1, dark: 0x5ED3A1)
    static let sky = Color(light: 0x58B0FF, dark: 0x58B0FF)
    static let sun = Color(light: 0xFFD84D, dark: 0xFFD84D)
    static let coral = Color(light: 0xFF7A70, dark: 0xFF7A70)
    static let pink = Color(light: 0xFFA6C9, dark: 0xFFA6C9)
    static let lavender = Color(light: 0xB9A4FF, dark: 0xB9A4FF)
}

private nonisolated func uiColor(hex: UInt32) -> UIColor {
    UIColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

private nonisolated func dynamicUIColor(light: UInt32, dark: UInt32) -> UIColor {
    UIColor { traits in
        uiColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
    }
}

private extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: dynamicUIColor(light: light, dark: dark))
    }
}

extension Font {
    static func gaegu(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo style: Font.TextStyle = .body
    ) -> Font {
        let name = switch weight {
        case .bold, .heavy, .black, .semibold: "Gaegu-Bold"
        case .light, .thin, .ultraLight: "Gaegu-Light"
        default: "Gaegu-Regular"
        }
        return .custom(name, size: size, relativeTo: style)
    }
}
