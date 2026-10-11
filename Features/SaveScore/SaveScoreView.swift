import SwiftUI

struct SaveScoreView: View {
    @State private var viewModel: SaveScoreViewModel
    @FocusState private var isNameFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(viewModel: SaveScoreViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        SheetScaffold(
            title: "Save Score",
            leading: .close { dismiss() },
            trailing: .confirm(isEnabled: viewModel.canSave) { save() }
        ) {
            VStack(spacing: 24) {
                VStack(spacing: 0) {
                    Text("Your Score")
                        .font(.gaegu(26, weight: .bold, relativeTo: .headline))
                        .foregroundStyle(Palette.ink.opacity(0.7))
                    OutlinedText("\(viewModel.scorePercent)%", size: 72)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        .padding(.top, 18)
                }
                .accessibilityElement(children: .combine)

                TextField("Your name", text: $viewModel.playerName)
                    .font(.gaegu(30, weight: .bold, relativeTo: .title3))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.center)
                    .textContentType(.nickname)
                    .submitLabel(.done)
                    .focused($isNameFocused)
                    .onSubmit(save)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .cartoonCard(radius: 26)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .onAppear { isNameFocused = true }
        .presentationDetents([.medium])
    }

    private func save() {
        guard viewModel.save() != nil else { return }
        dismiss()
    }
}

#Preview {
    SaveScoreView(
        viewModel: SaveScoreViewModel(score: 0.75, store: InMemoryLeaderboardStore()) { _ in }
    )
}
