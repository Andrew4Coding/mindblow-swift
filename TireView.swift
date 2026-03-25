import SwiftUI

struct TireView: View {
    let progress: Double
    let isExploded: Bool

    var body: some View {
        GeometryReader { geo in
            let baseSize = min(geo.size.width, geo.size.height) * 0.7
            let scale = 0.5 + (progress * 0.6)
            ZStack {
                Circle()
                    .strokeBorder(.black.opacity(0.7), lineWidth: 22)
                    .background(
                        Circle()
                            .fill(
                                RadialGradient(colors: [.gray.opacity(0.4), .black.opacity(0.8)], center: .center, startRadius: 0, endRadius: baseSize * 0.6)
                            )
                    )
                    .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 10)
                    .scaleEffect(isExploded ? 1.2 : scale)
                    .frame(width: baseSize, height: baseSize)

                Circle()
                    .fill(Color(white: 0.15))
                    .frame(width: baseSize * 0.35, height: baseSize * 0.35)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.4), lineWidth: 4)
                    )

                if isExploded {
                    Circle()
                        .fill(Color.red.opacity(0.4))
                        .frame(width: baseSize * 1.3, height: baseSize * 1.3)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: progress)
            .animation(.easeOut(duration: 0.2), value: isExploded)
        }
    }
}

#Preview {
    TireView(progress: 0.6, isExploded: false)
        .frame(width: 300, height: 300)
}