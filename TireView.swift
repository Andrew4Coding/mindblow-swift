import SwiftUI

struct TireView: View {
    let progress: Double
    let isExploded: Bool
    let isCalibrating: Bool
    let hasBlownOnce: Bool

    @State private var rotationAngle: Double = 0
    @State private var isSpinning: Bool = false

    var body: some View {
        GeometryReader { geo in
            let baseSize = min(geo.size.width, geo.size.height) * 0.8
            let scale = isExploded ? 1.05 : (0.9 + (progress * 0.35))
            let tireImage = isExploded ? "tire-full-flat" : "tire-full"
            ZStack {
                if isExploded {
                    Image("smoke")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: baseSize * 0.95)
                        .offset(x: baseSize * 0.36, y: baseSize * 0.08)
                        .opacity(0.9)
                        .transition(.opacity.combined(with: .scale))

                    Image("smoke")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: baseSize * 0.95)
                        .scaleEffect(x: -1, y: 1)
                        .offset(x: -baseSize * 0.36, y: baseSize * 0.1)
                        .opacity(0.9)
                        .transition(.opacity.combined(with: .scale))
                }

                Image(tireImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: baseSize, height: baseSize)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotationAngle))
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.25, dampingFraction: 0.72), value: progress)
            .animation(.easeOut(duration: 0.22), value: isExploded)
            .onAppear { updateRotationState() }
            .onChange(of: isCalibrating) { _ in updateRotationState() }
            .onChange(of: hasBlownOnce) { _ in updateRotationState() }
            .onChange(of: isExploded) { _ in updateRotationState() }
        }
    }

    private func updateRotationState() {
        let shouldSpin = isCalibrating && !hasBlownOnce && !isExploded
        if shouldSpin {
            guard !isSpinning else { return }
            isSpinning = true
            rotationAngle = 0
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        } else {
            guard isSpinning else { return }
            isSpinning = false
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                rotationAngle = 0
            }
        }
    }
}

#Preview {
    TireView(progress: 0.6, isExploded: false, isCalibrating: true, hasBlownOnce: false)
        .frame(width: 300, height: 300)
}