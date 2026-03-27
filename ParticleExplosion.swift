import SwiftUI

// MARK: - Particle Explosion View
struct ParticleExplosionView: View {
    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                ParticleView(index: index)
            }
        }
    }
}

struct ParticleView: View {
    let index: Int
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0

    let colors: [Color] = [.black, .gray]

    var body: some View {
        let angle = CGFloat(index) / 20.0 * .pi * 2
        let distance: CGFloat = 200
        let endX = cos(angle) * distance
        let endY = sin(angle) * distance
        let color = colors[index % colors.count]
        let randomScale = CGFloat.random(in: 1...2)

        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .scaleEffect(scale)
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                let delay = Double.random(in: 0...0.1)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 1.0)) {
                        offset = CGSize(width: endX, height: endY)
                        opacity = 0
                        scale = randomScale * 0.3
                    }
                }
            }
    }
}
