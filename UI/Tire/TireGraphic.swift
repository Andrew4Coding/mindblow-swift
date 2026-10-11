import SwiftUI

struct TireGraphic: View {
    let design: TireDesign
    var inflation: Double
    var stress: Double = 0

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let outer = size / 2 * (0.78 + 0.22 * inflation)
            let lugHeight = outer * design.lugHeight
            let bodyRadius = outer - lugHeight * 0.4
            let rimRadius = size / 2 * 0.78 * design.rimRatio

            ZStack {
                lugs(outer: outer, lugHeight: lugHeight)
                tireBody(radius: bodyRadius, rim: rimRadius)
                stressGlow(radius: bodyRadius)
                RimView(design: design, diameter: rimRadius * 2)
                highlight(radius: bodyRadius)
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func lugs(outer: CGFloat, lugHeight: CGFloat) -> some View {
        if design.lugCount > 0 {
            ForEach(0..<design.lugCount, id: \.self) { index in
                lugShape
                    .fill(design.lugColor)
                    .frame(width: outer * design.lugWidth * 2, height: lugHeight)
                    .offset(y: -(outer - lugHeight / 2))
                    .rotationEffect(.degrees(360 / Double(design.lugCount) * Double(index)))
            }
        }
    }

    private var lugShape: AnyShape {
        switch design.lugShape {
        case .block, .none: AnyShape(RoundedRectangle(cornerRadius: 2))
        case .chevron: AnyShape(ChevronShape())
        }
    }

    private func tireBody(radius: CGFloat, rim: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: design.bodyColors,
                        center: .center,
                        startRadius: rim,
                        endRadius: radius
                    )
                )
                .frame(width: radius * 2, height: radius * 2)

            if let stripe = design.stripe {
                Circle()
                    .stroke(stripe, lineWidth: max(2, radius * 0.045))
                    .frame(width: radius * 1.74, height: radius * 1.74)
            }

            Circle()
                .stroke(.black.opacity(0.55), lineWidth: max(2, radius * 0.04))
                .frame(width: rim * 2 + radius * 0.04, height: rim * 2 + radius * 0.04)
        }
    }

    private func stressGlow(radius: CGFloat) -> some View {
        Circle()
            .stroke(Color.red.opacity(stress * 0.7), lineWidth: radius * 0.05)
            .frame(width: radius * 1.94, height: radius * 1.94)
            .blur(radius: 1 + stress * 4)
    }

    private func highlight(radius: CGFloat) -> some View {
        Circle()
            .trim(from: 0.58, to: 0.72)
            .stroke(.white.opacity(0.28), style: StrokeStyle(lineWidth: radius * 0.07, lineCap: .round))
            .frame(width: radius * 1.78, height: radius * 1.78)
            .blur(radius: 1)
    }
}

private struct RimView: View {
    let design: TireDesign
    let diameter: CGFloat

    private var gradient: LinearGradient {
        LinearGradient(colors: design.rimColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        ZStack {
            switch design.rim {
            case .spokes(let count, let width):
                Circle().fill(Color(white: 0.06)).frame(width: diameter, height: diameter)
                ForEach(0..<count, id: \.self) { index in
                    Capsule()
                        .fill(gradient)
                        .frame(width: diameter * width, height: diameter * 0.42)
                        .offset(y: -diameter * 0.2)
                        .rotationEffect(.degrees(360 / Double(count) * Double(index)))
                }
                Circle().stroke(gradient, lineWidth: diameter * 0.07).frame(width: diameter * 0.93, height: diameter * 0.93)
                hub(0.3)

            case .disc(let holes):
                Circle().fill(gradient).frame(width: diameter, height: diameter)
                Circle().stroke(.black.opacity(0.35), lineWidth: diameter * 0.03).frame(width: diameter * 0.82, height: diameter * 0.82)
                ForEach(0..<holes, id: \.self) { index in
                    Circle()
                        .fill(Color(white: 0.05))
                        .frame(width: diameter * 0.11, height: diameter * 0.11)
                        .offset(y: -diameter * 0.3)
                        .rotationEffect(.degrees(360 / Double(holes) * Double(index)))
                }
                hub(0.28)

            case .wire(let count):
                Circle().stroke(gradient, lineWidth: diameter * 0.05).frame(width: diameter, height: diameter)
                ForEach(0..<count / 2, id: \.self) { index in
                    Capsule()
                        .fill(gradient)
                        .frame(width: max(1, diameter * 0.012), height: diameter * 0.95)
                        .rotationEffect(.degrees(360 / Double(count) * Double(index)))
                }
                hub(0.1)
            }
        }
        .frame(width: diameter, height: diameter)
    }

    private func hub(_ ratio: CGFloat) -> some View {
        ZStack {
            Circle().fill(gradient)
            Circle().stroke(.black.opacity(0.4), lineWidth: 1.5)
            Circle().fill(Color(white: 0.12)).frame(width: diameter * ratio * 0.35, height: diameter * ratio * 0.35)
        }
        .frame(width: diameter * ratio, height: diameter * ratio)
    }
}

private nonisolated struct ChevronShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.2))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.15 + rect.height * 0.2))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.2))
        path.closeSubpath()
        return path
    }
}

#Preview("All tires") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
            ForEach(TireSkin.allCases) { skin in
                VStack {
                    TireGraphic(design: skin.design, inflation: 0.7, stress: 0.3)
                        .frame(height: 150)
                    Text(skin.title)
                }
            }
        }
        .padding()
    }
}
