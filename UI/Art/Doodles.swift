import SwiftUI

nonisolated struct SparkleShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let tips = [
            CGPoint(x: rect.midX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.midY),
            CGPoint(x: rect.midX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.midY),
        ]
        var path = Path()
        path.move(to: tips[0])
        for tip in tips.dropFirst() + [tips[0]] {
            path.addQuadCurve(to: tip, control: c)
        }
        path.closeSubpath()
        return path
    }
}

nonisolated struct BurstShape: Shape {
    var spikes = 12
    var innerRatio: CGFloat = 0.62

    nonisolated func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        var path = Path()
        for step in 0..<(spikes * 2) {
            let radius = step.isMultiple(of: 2) ? outer : outer * innerRatio
            let angle = Double(step) / Double(spikes * 2) * 2 * .pi - .pi / 2
            let point = CGPoint(x: c.x + radius * CGFloat(cos(angle)), y: c.y + radius * CGFloat(sin(angle)))
            step == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

nonisolated struct SquiggleShape: Shape {
    var waves = 4

    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        let step = rect.width / CGFloat(waves * 2)
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        for index in 0..<(waves * 2) {
            let controlY = index.isMultiple(of: 2) ? rect.minY : rect.maxY
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + step * CGFloat(index + 1), y: rect.midY),
                control: CGPoint(x: rect.minX + step * (CGFloat(index) + 0.5), y: controlY)
            )
        }
        return path
    }
}

nonisolated struct CloudShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.addRoundedRect(
            in: CGRect(x: rect.minX, y: rect.minY + h * 0.45, width: w, height: h * 0.55),
            cornerSize: CGSize(width: h * 0.275, height: h * 0.275)
        )
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.14, y: rect.minY + h * 0.2, width: w * 0.34, height: h * 0.58))
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.4, y: rect.minY, width: w * 0.42, height: h * 0.78))
        return path
    }
}

nonisolated struct SmileShape: Shape {
    var depth: CGFloat = 1

    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 2 * depth)
        )
        return path
    }
}

nonisolated struct OpenMouthShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 2)
        )
        return path
    }
}

nonisolated struct CrossShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path
    }
}

struct DoodleFace: View {
    enum Mood {
        case happy, nervous, shocked, dead, cheer
    }

    let mood: Mood

    var body: some View {
        GeometryReader { proxy in
            let s = min(proxy.size.width, proxy.size.height)
            let line = max(2, s * 0.05)
            let ink = Color(red: 0.17, green: 0.16, blue: 0.2)

            ZStack {
                eyes(s: s, line: line, ink: ink)
                mouth(s: s, line: line, ink: ink)
                if mood == .happy || mood == .cheer {
                    Circle().fill(Palette.pink.opacity(0.85)).frame(width: s * 0.14, height: s * 0.14)
                        .offset(x: -s * 0.34, y: s * 0.1)
                    Circle().fill(Palette.pink.opacity(0.85)).frame(width: s * 0.14, height: s * 0.14)
                        .offset(x: s * 0.34, y: s * 0.1)
                }
                if mood == .nervous {
                    Circle().fill(Palette.sky).frame(width: s * 0.1, height: s * 0.13)
                        .offset(x: s * 0.4, y: -s * 0.32)
                }
            }
            .frame(width: s, height: s)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func eyes(s: CGFloat, line: CGFloat, ink: Color) -> some View {
        ForEach([-1.0, 1.0], id: \.self) { side in
            Group {
                switch mood {
                case .happy, .nervous:
                    Circle().fill(ink).frame(width: s * 0.13, height: s * 0.13)
                case .shocked:
                    Circle().fill(ink).frame(width: s * 0.22, height: s * 0.22)
                        .overlay(Circle().fill(.white).frame(width: s * 0.07, height: s * 0.07).offset(x: -s * 0.025, y: -s * 0.03))
                case .dead:
                    CrossShape()
                        .stroke(ink, style: StrokeStyle(lineWidth: line, lineCap: .round))
                        .frame(width: s * 0.14, height: s * 0.14)
                case .cheer:
                    SmileShape(depth: -1)
                        .stroke(ink, style: StrokeStyle(lineWidth: line, lineCap: .round))
                        .frame(width: s * 0.17, height: s * 0.08)
                }
            }
            .offset(x: s * 0.21 * side, y: -s * 0.14)
        }
    }

    @ViewBuilder
    private func mouth(s: CGFloat, line: CGFloat, ink: Color) -> some View {
        Group {
            switch mood {
            case .happy:
                SmileShape(depth: 0.6)
                    .stroke(ink, style: StrokeStyle(lineWidth: line, lineCap: .round))
                    .frame(width: s * 0.3, height: s * 0.1)
            case .nervous:
                SquiggleShape(waves: 2)
                    .stroke(ink, style: StrokeStyle(lineWidth: line, lineCap: .round))
                    .frame(width: s * 0.3, height: s * 0.07)
            case .shocked:
                Ellipse().fill(ink).frame(width: s * 0.15, height: s * 0.2)
            case .dead:
                SquiggleShape(waves: 3)
                    .stroke(ink, style: StrokeStyle(lineWidth: line, lineCap: .round))
                    .frame(width: s * 0.36, height: s * 0.07)
            case .cheer:
                OpenMouthShape()
                    .fill(ink)
                    .frame(width: s * 0.34, height: s * 0.14)
                    .overlay(alignment: .bottom) {
                        Capsule().fill(Palette.coral).frame(width: s * 0.14, height: s * 0.06).offset(y: -s * 0.015)
                    }
            }
        }
        .offset(y: s * 0.17)
    }
}

#Preview {
    HStack {
        ForEach([DoodleFace.Mood.happy, .nervous, .shocked, .dead, .cheer], id: \.self) { mood in
            DoodleFace(mood: mood).frame(width: 64, height: 64)
                .background(Circle().fill(Palette.cream))
        }
    }
    .padding()
}
