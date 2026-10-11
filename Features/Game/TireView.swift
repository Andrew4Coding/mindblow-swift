import SwiftUI

struct TireView: View {
    let progress: Double
    let isExploded: Bool
    let isFinished: Bool
    let hasBlownOnce: Bool
    let skin: TireSkin

    private static let ringHidingDelay: Duration = .seconds(2)
    private static let ringHidingProgress = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var smokeOpacity = 0.0
    @State private var smokeSpread: CGFloat = 0
    @State private var bounceOffset: CGFloat = 0
    @State private var squash: CGFloat = 0
    @State private var showsBurst = false
    @State private var isRingHidden = false

    private var stress: Double {
        guard !isExploded else { return 0 }
        let value = max(0, (progress - 0.6) / 0.4)
        return min(1, value * value)
    }

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let size = min(proxy.size.width, proxy.size.height) * 0.92
                ZStack {
                    if !isExploded {
                        Circle()
                            .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 9]))
                            .foregroundStyle(Palette.ink.opacity(0.55))
                            .frame(width: size, height: size)
                            .opacity(isRingHidden ? 0 : 1)
                    }

                    TimelineView(.animation(minimumInterval: 1.0 / 60, paused: stress < 0.01 || reduceMotion)) { context in
                        let time = context.date.timeIntervalSinceReferenceDate
                        TireGraphic(
                            design: skin.design,
                            inflation: isExploded ? 1 : progress,
                            stress: stress
                        )
                        .frame(width: size, height: size)
                        .clipShape(FlatBottomShape(amount: squash))
                        .scaleEffect(x: 1 + 0.05 * squash, y: 1 - 0.06 * squash, anchor: .bottom)
                        .rotationEffect(.degrees(sin(time * 47) * stress * 1.8))
                        .offset(x: sin(time * 55) * stress * 5, y: bounceOffset)
                        .shadow(color: .black.opacity(0.22), radius: 10, y: 6)
                    }
                    .animation(.spring(response: 0.25, dampingFraction: 0.72), value: progress)

                    if isExploded {
                        smoke(baseSize: size * 0.8, side: 1)
                        smoke(baseSize: size * 0.8, side: -1)
                    }

                    if showsBurst {
                        BurstEffectView(tint: skin.design.debrisColor)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tire")
        .accessibilityValue(accessibilityValue)
        .task(id: isExploded) { await playExplosion() }
        .task(id: isFinished && !isExploded) { await playFinished() }
        .task(id: hasBlownOnce) { await hideRingAfterDelay() }
        .onChange(of: progress >= Self.ringHidingProgress) { _, reached in
            if reached { hideRing() }
        }
        .onChange(of: progress == 0 && !hasBlownOnce) { _, isFreshRound in
            if isFreshRound { isRingHidden = false }
        }
    }

    private var accessibilityValue: Text {
        isExploded ? Text("Burst") : Text("\(Int(progress * 100)) percent inflated")
    }

    private func smoke(baseSize: CGFloat, side: CGFloat) -> some View {
        Image("smoke")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: baseSize * 0.95)
            .scaleEffect(x: side, y: 1)
            .offset(x: baseSize * 0.36 * side + smokeSpread * side, y: baseSize * 0.3)
            .opacity(smokeOpacity)
            .transition(.opacity.combined(with: .scale))
    }

    private func hideRingAfterDelay() async {
        guard hasBlownOnce else { return }
        do {
            try await Task.sleep(for: Self.ringHidingDelay)
        } catch {
            return
        }
        hideRing()
    }

    private func hideRing() {
        guard !isRingHidden else { return }
        withAnimation(.easeOut(duration: 0.4)) { isRingHidden = true }
    }

    private func playFinished() async {
        guard isFinished && !isExploded, !reduceMotion else { return }
        withAnimation(.easeOut(duration: 0.15)) { bounceOffset = -24 }
        try? await Task.sleep(for: .milliseconds(150))
        withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) { bounceOffset = 0 }
    }

    private func playExplosion() async {
        guard isExploded else {
            withAnimation(.easeOut(duration: 0.25)) {
                squash = 0
                bounceOffset = 0
            }
            smokeOpacity = 0
            smokeSpread = 0
            showsBurst = false
            return
        }

        smokeOpacity = 0
        smokeSpread = 0
        showsBurst = true

        withAnimation(.easeOut(duration: 0.35)) { smokeOpacity = 0.95 }
        if !reduceMotion {
            withAnimation(.easeOut(duration: 0.12)) {
                bounceOffset = -70
                squash = 0.35
            }
        } else {
            squash = 1
        }

        let steps: [(Duration, () -> Void)] = [
            (.milliseconds(120), {
                withAnimation(.easeIn(duration: 0.14)) { bounceOffset = 0 }
            }),
            (.milliseconds(140), {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) { squash = 1 }
            }),
            (.milliseconds(300), {
                withAnimation(.easeInOut(duration: 1)) {
                    smokeOpacity = 0
                    smokeSpread = 60
                }
            }),
            (.milliseconds(800), { showsBurst = false }),
        ]
        for (delay, step) in steps {
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }
            step()
        }
    }
}

private nonisolated struct FlatBottomShape: Shape {
    var amount: CGFloat

    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }

    nonisolated func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2 + 8
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let softness = radius * 0.07
        let flatDepth = rect.height * 0.14
        let limit = center.y + radius - 8 + 6 * softness * (1 - amount) - amount * flatDepth

        var path = Path()
        let steps = 120
        for step in 0...steps {
            let angle = Double(step) / Double(steps) * 2 * .pi
            let x = center.x + radius * CGFloat(cos(angle))
            let y = center.y + radius * CGFloat(sin(angle))
            let softMin = -softness * log(exp(-y / softness + limit / softness) + 1) + limit
            let point = CGPoint(x: x, y: min(y, softMin))
            step == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

#Preview("Inflating") {
    TireView(
        progress: 0.6,
        isExploded: false,
        isFinished: false,
        hasBlownOnce: true,
        skin: .car
    )
    .frame(width: 300, height: 300)
}

#Preview("Strained") {
    TireView(
        progress: 0.95,
        isExploded: false,
        isFinished: false,
        hasBlownOnce: true,
        skin: .racing
    )
    .frame(width: 300, height: 300)
}

#Preview("Exploded") {
    TireView(
        progress: 1,
        isExploded: true,
        isFinished: true,
        hasBlownOnce: true,
        skin: .truck
    )
    .frame(width: 300, height: 300)
}
