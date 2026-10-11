import SwiftUI

struct GameModeSelectionView: View {
    let canDismiss: Bool
    let onSelect: (GameMode) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        SheetScaffold(
            title: "Choose Game Mode",
            leading: canDismiss ? .close { dismiss() } : nil
        ) {
            ScrollView {
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(spacing: 20))
                    : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
                layout { cards }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var cards: some View {
        ForEach(GameMode.allCases) { mode in
            Button {
                onSelect(mode)
            } label: {
                VStack(spacing: 10) {
                    ModeArt(mode: mode)
                        .frame(height: 120)
                    VStack(spacing: 0) {
                        Text(mode.title)
                            .font(.gaegu(30, weight: .bold, relativeTo: .title2))
                            .foregroundStyle(Palette.ink)
                        Text(mode.subtitle)
                            .font(.gaegu(21, relativeTo: .subheadline))
                            .foregroundStyle(Palette.ink.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .cartoonCard(fill: Palette.card)
                .contentShape(.rect(cornerRadius: 28))
            }
            .buttonStyle(CartoonPressStyle())
            .accessibilityElement(children: .combine)
        }
    }
}

private struct ModeArt: View {
    let mode: GameMode

    private let outline = Color(red: 0.17, green: 0.16, blue: 0.2)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous).fill(mode.tint)
            SparkleShape().fill(.white.opacity(0.85))
                .frame(width: 22, height: 22)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(12)
            CloudShape().fill(.white.opacity(0.55))
                .frame(width: 50, height: 30)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(10)
            switch mode {
            case .single:
                face(color: Palette.sun, mood: .cheer, size: 84)
            case .twoPlayer:
                HStack(spacing: -14) {
                    face(color: Palette.sun, mood: .happy, size: 64)
                        .rotationEffect(.degrees(-8))
                    face(color: Palette.card, mood: .shocked, size: 64)
                        .rotationEffect(.degrees(8))
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(outline, lineWidth: 1.5))
        .environment(\.colorScheme, .light)
        .accessibilityHidden(true)
    }

    private func face(color: Color, mood: DoodleFace.Mood, size: CGFloat) -> some View {
        DoodleFace(mood: mood)
            .padding(size * 0.05)
            .frame(width: size, height: size)
            .background(Circle().fill(color))
            .overlay(Circle().stroke(outline, lineWidth: 2))
    }
}

private struct CartoonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

#Preview {
    Text("Game")
        .sheet(isPresented: .constant(true)) {
            GameModeSelectionView(canDismiss: false) { _ in }
        }
}
