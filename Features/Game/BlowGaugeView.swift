import SwiftUI

struct BlowGaugeView: View {
    let blowIntensity: Double

    private var gaugeColor: Color {
        Color(hue: 0.38 * (1 - min(1, max(0, blowIntensity))), saturation: 0.62, brightness: 1)
    }

    var body: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(Palette.card)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(gaugeColor)
                        .overlay(Capsule().stroke(Palette.ink, lineWidth: 1.5))
                        .frame(width: max(proxy.size.width * blowIntensity, proxy.size.height))
                        .overlay(alignment: .trailing) {
                            Image(systemName: "wind")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundStyle(Palette.onAccent)
                                .padding(.trailing, 7)
                        }
                }
                .overlay(Capsule().stroke(Palette.ink, lineWidth: 1.5))
        }
        .frame(height: 24)
        .animation(.easeOut(duration: 0.12), value: blowIntensity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Blow strength")
        .accessibilityValue("\(Int(blowIntensity * 100)) percent")
    }
}

#Preview {
    BlowGaugeView(blowIntensity: 0.65)
        .padding()
}
