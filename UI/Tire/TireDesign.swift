import SwiftUI

struct TireDesign {
    enum LugShape {
        case block
        case chevron
        case none
    }

    enum Rim {
        case spokes(count: Int, width: CGFloat)
        case disc(holes: Int)
        case wire(count: Int)
    }

    let lugCount: Int
    let lugWidth: CGFloat
    let lugHeight: CGFloat
    let lugShape: LugShape
    let rimRatio: CGFloat
    let rim: Rim
    let rimColors: [Color]
    let stripe: Color?
    let bodyColors: [Color]
    let lugColor: Color

    var debrisColor: Color { lugColor }
}

extension TireSkin {
    var design: TireDesign {
        let rubber = [Color(white: 0.24), Color(white: 0.11)]
        let lug = Color(white: 0.05)
        let silver = [Color(white: 0.96), Color(white: 0.62)]

        switch self {
        case .car:
            return TireDesign(
                lugCount: 40, lugWidth: 0.075, lugHeight: 0.07, lugShape: .block,
                rimRatio: 0.62, rim: .spokes(count: 5, width: 0.16), rimColors: silver,
                stripe: nil, bodyColors: rubber, lugColor: lug
            )
        case .truck:
            return TireDesign(
                lugCount: 22, lugWidth: 0.13, lugHeight: 0.105, lugShape: .block,
                rimRatio: 0.55, rim: .disc(holes: 8),
                rimColors: [Color(white: 0.55), Color(white: 0.2)],
                stripe: Color.orange, bodyColors: rubber, lugColor: lug
            )
        case .motor:
            return TireDesign(
                lugCount: 30, lugWidth: 0.085, lugHeight: 0.085, lugShape: .chevron,
                rimRatio: 0.66, rim: .spokes(count: 7, width: 0.07),
                rimColors: [Color(red: 1, green: 0.82, blue: 0.3), Color(red: 0.75, green: 0.5, blue: 0.1)],
                stripe: nil, bodyColors: rubber, lugColor: lug
            )
        case .bicycle:
            return TireDesign(
                lugCount: 56, lugWidth: 0.03, lugHeight: 0.035, lugShape: .block,
                rimRatio: 0.88, rim: .wire(count: 16),
                rimColors: [Color(white: 0.95), Color(white: 0.7)],
                stripe: nil, bodyColors: [Color(white: 0.2), Color(white: 0.12)], lugColor: lug
            )
        case .racing:
            return TireDesign(
                lugCount: 0, lugWidth: 0, lugHeight: 0, lugShape: .none,
                rimRatio: 0.64, rim: .spokes(count: 10, width: 0.07),
                rimColors: [Color(white: 0.98), Color(white: 0.75)],
                stripe: Color(red: 0.95, green: 0.15, blue: 0.2), bodyColors: [Color(white: 0.16), Color(white: 0.07)],
                lugColor: Color(white: 0.04)
            )
        case .tractor:
            return TireDesign(
                lugCount: 12, lugWidth: 0.24, lugHeight: 0.22, lugShape: .chevron,
                rimRatio: 0.5, rim: .disc(holes: 6),
                rimColors: [Color(red: 0.95, green: 0.3, blue: 0.2), Color(red: 0.6, green: 0.12, blue: 0.1)],
                stripe: nil, bodyColors: rubber, lugColor: lug
            )
        }
    }
}
