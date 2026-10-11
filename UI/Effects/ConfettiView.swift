import SwiftUI

struct ConfettiView: View {
    private static let colors: [Color] = [Palette.coral, Palette.sun, Palette.mint, Palette.sky, Palette.lavender, Palette.pink]

    @State private var pieces = (0..<60).map { ConfettiPiece(id: $0, color: colors[$0 % colors.count]) }

    var body: some View {
        GeometryReader { proxy in
            ForEach(pieces) { piece in
                ConfettiPieceView(piece: piece, size: proxy.size)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct ConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let startX = CGFloat.random(in: 0...1)
    let drift = CGFloat.random(in: -60...60)
    let duration = Double.random(in: 2.2...3.6)
    let delay = Double.random(in: 0...0.5)
    let spin = Double.random(in: 180...720)
    let width = CGFloat.random(in: 6...10)
    let aspect = CGFloat.random(in: 1.2...2)

    var shape: AnyShape {
        switch id % 3 {
        case 0: AnyShape(SparkleShape())
        case 1: AnyShape(Capsule())
        default: AnyShape(Circle())
        }
    }
}

private struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let size: CGSize

    @State private var hasFallen = false

    var body: some View {
        piece.shape
            .fill(piece.color)
            .overlay(piece.shape.stroke(Color(red: 0.17, green: 0.16, blue: 0.2), lineWidth: 1.5))
            .frame(width: piece.width * 1.4, height: piece.width * 1.4 * (piece.id.isMultiple(of: 3) ? 1 : piece.aspect))
            .rotationEffect(.degrees(hasFallen ? piece.spin : 0))
            .position(
                x: piece.startX * size.width + (hasFallen ? piece.drift : 0),
                y: hasFallen ? size.height + 40 : -20
            )
            .opacity(hasFallen ? 0.3 : 1)
            .onAppear {
                withAnimation(.easeIn(duration: piece.duration).delay(piece.delay)) {
                    hasFallen = true
                }
            }
    }
}

#Preview {
    ConfettiView()
}
