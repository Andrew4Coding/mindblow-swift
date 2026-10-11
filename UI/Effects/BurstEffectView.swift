import SwiftUI

struct BurstEffectView: View {
    let tint: Color

    @State private var isExpanded = false
    @State private var pieces = (0..<16).map { BurstPiece(index: $0, total: 16) }

    var body: some View {
        ZStack {
            BurstShape(spikes: 11, innerRatio: 0.55)
                .fill(Palette.sun)
                .overlay(BurstShape(spikes: 11, innerRatio: 0.55).stroke(Color(red: 0.17, green: 0.16, blue: 0.2), lineWidth: 5))
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(isExpanded ? 12 : -8))
                .scaleEffect(isExpanded ? 1.5 : 0.2)
                .opacity(isExpanded ? 0 : 1)

            Circle()
                .stroke(Palette.coral, lineWidth: isExpanded ? 1 : 12)
                .frame(width: 160, height: 160)
                .scaleEffect(isExpanded ? 2.4 : 0.3)
                .opacity(isExpanded ? 0 : 0.9)

            Text(verbatim: "BOOM!")
                .font(.gaegu(54, weight: .bold))
                .foregroundStyle(Palette.coral)
                .shadow(color: Color(red: 0.17, green: 0.16, blue: 0.2), radius: 0, x: 2, y: 2)
                .rotationEffect(.degrees(isExpanded ? -10 : 6))
                .scaleEffect(isExpanded ? 1.3 : 0.4)
                .opacity(isExpanded ? 0 : 1)
                .offset(y: isExpanded ? -40 : 0)

            ForEach(pieces) { piece in
                piece.shape
                    .fill(piece.isSpark ? Palette.sun : tint)
                    .overlay(piece.shape.stroke(Color(red: 0.17, green: 0.16, blue: 0.2), lineWidth: 1.5))
                    .frame(width: piece.size, height: piece.isSpark ? piece.size : piece.size * 0.6)
                    .rotationEffect(.degrees(isExpanded ? piece.spin : 0))
                    .offset(
                        x: isExpanded ? cos(piece.angle) * piece.distance : 0,
                        y: isExpanded ? sin(piece.angle) * piece.distance + 90 : 0
                    )
                    .opacity(isExpanded ? 0 : 1)
                    .animation(.easeOut(duration: piece.duration), value: isExpanded)
            }
        }
        .animation(.easeOut(duration: 0.7), value: isExpanded)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { isExpanded = true }
    }
}

private struct BurstPiece: Identifiable {
    let index: Int
    let total: Int
    let distance = CGFloat.random(in: 110...230)
    let size = CGFloat.random(in: 12...22)
    let spin = Double.random(in: -540...540)
    let duration = Double.random(in: 0.7...1.1)

    var id: Int { index }
    var angle: CGFloat { CGFloat(index) / CGFloat(total) * .pi * 2 + CGFloat.random(in: -0.15...0.15) }
    var isSpark: Bool { index.isMultiple(of: 4) }
    var shape: AnyShape { isSpark ? AnyShape(SparkleShape()) : AnyShape(RoundedRectangle(cornerRadius: 3)) }
}

#Preview {
    BurstEffectView(tint: .black)
        .frame(width: 400, height: 400)
}
