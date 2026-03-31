import SwiftUI

struct TireView: View {
    let progress: Double
    let isExploded: Bool
    let isCalibrating: Bool
    let hasBlownOnce: Bool
    let hasStartedRecording: Bool
    let onTapExplosion: (() -> Void)?
    let maxPSI: Double
    let isFinished: Bool
    let currentPlayer: Int?
    let isOuterRingLocked: Bool

    @State private var rotationAngle: Double = 0
    @State private var isSpinning: Bool = false
    @State private var smokeOpacity: Double = 0
    @State private var smokeOffsetLeft: CGFloat = 0
    @State private var smokeOffsetRight: CGFloat = 0
    @State private var bounceOffset: CGFloat = 0
    @State private var isParticleExplosion: Bool = false
    @State private var explosionPhase: Int = 0
    @State private var outerRingOpacity: Double = 1.0
    @State private var hasOuterRingFaded: Bool = false
    @State private var isLongPressing: Bool = false

    var body: some View {
        ZStack {
            // Tire container
            GeometryReader { geo in
                let baseSize = min(geo.size.width, geo.size.height) * 0.8
                let scale = isExploded ? 1.05 : (0.8 + (progress * 0.4))
                let tireImage: String = {
                    if !isExploded {
                        return "tire-full"
                    } else if explosionPhase == 1 {
                        return "tire-full-semiflat"
                    } else {
                        return "tire-full-flat"
                    }
                }()
                let tireBaseSize = isExploded ? baseSize * 0.95 : baseSize
                ZStack {
                    if !isExploded {
                        Circle()
                            .stroke(
                                style: StrokeStyle(
                                    lineWidth: 2,
                                    dash: [5, 5]
                                )
                            )
                            .foregroundColor(.gray.opacity(0.5))
                            .frame(width: tireBaseSize, height: tireBaseSize)
                            .scaleEffect(1.2)
                            .opacity(outerRingOpacity)
                    }

                    Image(tireImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: tireBaseSize, height: tireBaseSize)
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(rotationAngle))
                        .offset(y: bounceOffset)
                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
                        .listRowInsets(EdgeInsets())

                    if isExploded {
                        Image("smoke")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: baseSize * 0.95)
                            .offset(
                                x: baseSize * 0.36 + smokeOffsetRight,
                                y: baseSize * 0.25
                            )
                            .opacity(smokeOpacity)
                            .transition(.opacity.combined(with: .scale))

                        Image("smoke")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: baseSize * 0.95)
                            .scaleEffect(x: -1, y: 1)
                            .offset(
                                x: -baseSize * 0.36 + smokeOffsetLeft,
                                y: baseSize * 0.25
                            )
                            .opacity(smokeOpacity)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(
                    .spring(response: 0.25, dampingFraction: 0.72),
                    value: progress
                )
                .animation(.easeOut(duration: 0.22), value: isExploded)
                .onAppear { updateRotationState() }
                .onChange(of: isCalibrating) { updateRotationState() }
                .onChange(of: isOuterRingLocked) { oldValue, newValue in
                    if newValue && !oldValue {
                        hasOuterRingFaded = false
                        outerRingOpacity = 1.0
                    }
                }
                .onChange(of: hasBlownOnce) { oldValue, newValue in
                    updateRotationState()
                    if !isOuterRingLocked && !hasOuterRingFaded {
                        if newValue && !oldValue {
                            withAnimation(.easeOut(duration: 1.0).delay(2.0)) {
                                outerRingOpacity = 0
                            }
                            hasOuterRingFaded = true
                        } else if !newValue && oldValue {
                            withAnimation(.easeIn(duration: 0.3)) {
                                outerRingOpacity = 1.0
                            }
                        }
                    }
                }
                .onChange(of: isExploded) { oldValue, newValue in
                    updateRotationState()
                    if newValue {
                        triggerExplosionBounce()
                        handleSmoke(for: newValue)
                    } else {
                        handleSmoke(for: newValue)
                        explosionPhase = 0
                    }
                }
                .onChange(of: isFinished) { oldValue, newValue in
                    if newValue {
                        withAnimation(.easeIn(duration: 0.3)) {
                            outerRingOpacity = 1.0
                        }
                    }
                }
            }

            // Particle explosion (on top, full screen)
            if isParticleExplosion {
                ParticleExplosionView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func updateRotationState() {
        isSpinning = false
        rotationAngle = 0
    }

    private func triggerExplosionBounce() {
        // Trigger particle explosion
        isParticleExplosion = true

        // Animate bounce up
        withAnimation(.easeOut(duration: 0.12)) {
            bounceOffset = -80
        }

        // Transition to semiflat phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeInOut(duration: 0.08)) {
                explosionPhase = 1
            }
        }

        // Transition to fully flat phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.08)) {
                explosionPhase = 2
            }
        }

        // Bounce back down
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeIn(duration: 0.15)) {
                bounceOffset = 0
            }
        }

        // Turn off particles after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isParticleExplosion = false
        }
    }

    private func handleSmoke(for exploded: Bool) {
        guard exploded else {
            smokeOpacity = 0
            smokeOffsetLeft = 0
            smokeOffsetRight = 0
            return
        }

        smokeOpacity = 0
        smokeOffsetLeft = 0
        smokeOffsetRight = 0

        withAnimation(.easeOut(duration: 0.35)) {
            smokeOpacity = 0.95
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 1.0)) {
                smokeOpacity = 0
                smokeOffsetLeft = -60
                smokeOffsetRight = 60
            }
        }
    }
}

#Preview {
    TireView(
        progress: 0.6,
        isExploded: false,
        isCalibrating: true,
        hasBlownOnce: false,
        hasStartedRecording: true,
        onTapExplosion: nil,
        maxPSI: 20,
        isFinished: false,
        currentPlayer: nil,
        isOuterRingLocked: false
    )
    .frame(width: 300, height: 300)
}
