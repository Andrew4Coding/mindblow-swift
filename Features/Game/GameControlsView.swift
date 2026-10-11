import SwiftUI

struct GameControlsView: View {
    let viewModel: GameViewModel

    var body: some View {
        Group {
            switch viewModel.phase {
            case .awaitingStart:
                EmptyView()
            case .playing:
                playingControls
            case .finished, .exploded:
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 14) { finishedButtons }
                    VStack(spacing: 14) { finishedButtons }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56)
    }

    private var playingControls: some View {
        VStack(spacing: 14) {
            ZStack {
                Color.clear
                if viewModel.canPass {
                    Button("Pass", systemImage: "checkmark", action: viewModel.finish)
                        .labelStyle(AnimatedCheckmarkLabelStyle())
                        .buttonStyle(.cartoon(fill: Palette.mint))
                } else if viewModel.canEndRun {
                    Button("Had enough?", systemImage: "checkmark", action: viewModel.finish)
                        .labelStyle(AnimatedCheckmarkLabelStyle())
                        .buttonStyle(.cartoon(fill: Palette.mint))
                }
            }
            .frame(height: 56)

            HoldToInflateButton(
                isEnabled: viewModel.canInflate,
                onPressChanged: { $0 ? viewModel.beginHolding() : viewModel.endHolding() },
                onActivate: viewModel.pumpOnce
            )
        }
    }

    @ViewBuilder
    private var finishedButtons: some View {
        Button("Blow Again!", systemImage: "arrow.trianglehead.clockwise", action: viewModel.startNewSession)
            .buttonStyle(.cartoon(fill: Palette.sky))

        if viewModel.canSaveScore {
            Button("Save Score", systemImage: "list.clipboard") { viewModel.present(.saveScore) }
                .buttonStyle(.cartoon(fill: Palette.mint))
        }
    }
}

private struct AnimatedCheckmarkLabelStyle: LabelStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
        } icon: {
            configuration.icon
                .bouncingSymbol(isActive: !reduceMotion)
        }
    }
}

#Preview("Playing") {
    GameControlsView(viewModel: .preview(phase: .playing))
        .padding()
}
