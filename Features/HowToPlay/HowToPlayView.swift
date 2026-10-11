import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SheetScaffold(title: "How to Play", trailing: .confirm { dismiss() }) {
            ScrollView {
                VStack(spacing: 20) {
                    art
                        .frame(height: 150)

                    Text("Blow hard, but not too much!")
                        .font(.gaegu(30, weight: .bold, relativeTo: .title3))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 14) {
                        step("wind", Palette.sky, "Blow toward the bottom of your phone to inflate the tire.")
                        step("checkmark.circle", Palette.mint, "Stop before it pops. The tire bursts at a hidden pressure.")
                        step("hand.tap", Palette.sun, "Can't blow? Press and hold \"Hold to Inflate\" instead.")
                        step("person.2", Palette.pink, "In two-player mode, pass the phone after each turn.")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var art: some View {
        let outline = Color(red: 0.17, green: 0.16, blue: 0.2)
        return ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Palette.sun)
            SparkleShape().fill(.white.opacity(0.85))
                .frame(width: 26, height: 26)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)
            CloudShape().fill(.white.opacity(0.55))
                .frame(width: 64, height: 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(14)
            HStack(spacing: 10) {
                DoodleFace(mood: .shocked)
                    .padding(5)
                    .frame(width: 92, height: 92)
                    .background(Circle().fill(Palette.card))
                    .overlay(Circle().stroke(outline, lineWidth: 2))
                VStack(spacing: 10) {
                    SquiggleShape(waves: 3).stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 70, height: 12)
                    SquiggleShape(waves: 3).stroke(Palette.sky, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 90, height: 12)
                    SquiggleShape(waves: 3).stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 70, height: 12)
                }
                Circle().fill(Palette.mint)
                    .overlay(Circle().stroke(outline, lineWidth: 2))
                    .frame(width: 50, height: 50)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(outline, lineWidth: 1.5))
        .environment(\.colorScheme, .light)
        .accessibilityHidden(true)
    }

    private func step(_ symbol: String, _ color: Color, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Palette.onAccent)
                .frame(width: 46, height: 46)
                .cartoonSurface(Circle(), fill: color, lift: 2)
            Text(text)
                .font(.gaegu(24, relativeTo: .body))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .cartoonCard(radius: 24)
    }
}

#Preview {
    HowToPlayView()
}
