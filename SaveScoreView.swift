import SwiftUI

struct SaveScoreView: View {
    @Environment(\.dismiss) var dismiss
    let score: Double
    var onSave: (LeaderboardEntry) -> Void
    
    @State private var playerName: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Your Score")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("\(Int(score * 100))%")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(.blue)
                
                TextField("Enter your name", text: $playerName)
                    .textFieldStyle(.automatic)
                    .padding(.horizontal, 40)
                
                Button(action: {
                    let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedName.isEmpty else { return }
                    
                    let entry = LeaderboardEntry(playerName: trimmedName, score: score)
                    LeaderboardManager.shared.saveEntry(entry)
                    onSave(entry)
                    dismiss()
                }) {
                    Text("Save Score")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Save Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    SaveScoreView(score: 0.75) { _ in }
}
