import SwiftUI

struct LeaderboardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var entries: [LeaderboardEntry] = []
    @State private var showClearConfirmation = false
    
    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "trophy")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No scores yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                            HStack {
                                Text("#\(index + 1)")
                                    .font(.headline.bold())
                                    .foregroundColor(index == 0 ? .yellow : (index == 1 ? .gray : (index == 2 ? .orange : .primary)))
                                    .frame(width: 50)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.playerName)
                                        .font(.headline)
                                    Text(entry.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("\(Int(entry.score * 100))%")
                                    .font(.title2.bold())
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if !entries.isEmpty {
                        Button("Clear") {
                            showClearConfirmation = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert("Clear Leaderboard?", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    LeaderboardManager.shared.clearLeaderboard()
                    entries = []
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            entries = LeaderboardManager.shared.getSortedEntries()
        }
    }
}

#Preview {
    LeaderboardView()
}
