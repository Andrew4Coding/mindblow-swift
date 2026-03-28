import SwiftUI

struct BlowGaugeView: View {
    let blowIntensity: Double

    var gaugeColor: Color {
        if blowIntensity < 0.5 {
            // Green to Yellow
            let progress = blowIntensity * 2
            let red = progress
            let green = 1.0
            return Color(red: red, green: green, blue: 0)
        } else {
            // Yellow to Red
            let progress = (blowIntensity - 0.5) * 2
            let red = 1.0
            let green = 1 - progress
            return Color(red: red, green: green, blue: 0)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(gaugeColor)
                    
                    Image(systemName: "wind")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                }
                .frame(width: max(geometry.size.width * blowIntensity, 20))
            }
            .frame(height: 20)
        }
        .background(Color.gray.opacity(0.2))
        .frame(height: 20)
        .cornerRadius(12)
        .animation(.easeOut(duration: 0.12), value: blowIntensity)
    }
}

#Preview {
    BlowGaugeView(blowIntensity: 0.65)
        .padding()
}
