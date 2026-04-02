import SwiftUI

enum GameMode: String, CaseIterable {
    case single = "Single Player"
    case twoPlayer = "Two Player"
}

struct GameModeSelectionView: View {
    @Environment(\.dismiss) var dismiss
    var onSelect: (GameMode) -> Void
    var onRestart: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                HStack(spacing: 20) {
                    ForEach(GameMode.allCases, id: \.self) { mode in
                        VStack (spacing: 12) {
                            Image(mode == .single ? "ilustration-blow" : "ilustration-2p")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 180)
                            Text(mode.rawValue)
                                .font(.headline)
                        }
                        .onTapGesture {
                            dismiss()
                            onRestart()
                            onSelect(mode)
                        }
                    }
                }
                .padding(.horizontal, 40)
                Spacer()
            }
            .navigationTitle("Choose Game Mode")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    GameModeSelectionView(
        onSelect: { _ in },
        onRestart: { }
    )
}
