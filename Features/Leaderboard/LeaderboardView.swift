import SwiftUI

struct LeaderboardView: View {
    @State private var viewModel: LeaderboardViewModel
    @State private var showsClearConfirmation = false
    @Environment(\.dismiss) private var dismiss

    init(viewModel: LeaderboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        SheetScaffold(
            title: "Leaderboard",
            leading: .close { dismiss() },
            trailing: viewModel.isEmpty ? nil : HeaderAction(
                systemImage: "trash",
                label: "Clear",
                fill: Palette.coral,
                foreground: Palette.onAccent
            ) { showsClearConfirmation = true }
        ) {
            if viewModel.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.rankedEntries) { ranked in
                            LeaderboardRow(ranked: ranked)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
        .confirmationDialog(
            "Clear Leaderboard?",
            isPresented: $showsClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All Scores", role: .destructive) { viewModel.clear() }
        } message: {
            Text("This action cannot be undone.")
        }
        .presentationDetents([.medium, .large])
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            DoodleFace(mood: .nervous)
                .frame(width: 96, height: 96)
                .background(Circle().fill(Palette.sun))
                .overlay(Circle().stroke(Palette.ink, lineWidth: 3))
            Text("No Scores Yet")
                .font(.gaegu(34, weight: .bold, relativeTo: .title2))
                .foregroundStyle(Palette.ink)
            Text("Finish a single-player round and save your score.")
                .font(.gaegu(23, relativeTo: .body))
                .foregroundStyle(Palette.ink.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct LeaderboardRow: View {
    let ranked: RankedEntry

    var body: some View {
        HStack(spacing: 14) {
            Text("\(ranked.rank)")
                .font(.gaegu(28, weight: .bold).monospacedDigit())
                .foregroundStyle(Palette.onAccent)
                .frame(width: 48, height: 48)
                .cartoonSurface(Circle(), fill: medalColor, lift: 2)

            VStack(alignment: .leading, spacing: 0) {
                Text(ranked.entry.playerName)
                    .font(.gaegu(28, weight: .bold, relativeTo: .headline))
                    .foregroundStyle(Palette.ink)
                Text(ranked.entry.date, style: .date)
                    .font(.gaegu(19, relativeTo: .caption))
                    .foregroundStyle(Palette.ink.opacity(0.6))
            }

            Spacer()

            Text("\(Int(ranked.entry.score * 100))%")
                .font(.gaegu(40, weight: .bold, relativeTo: .title).monospacedDigit())
                .foregroundStyle(Palette.ink)
        }
        .padding(12)
        .cartoonCard(radius: 24)
        .accessibilityElement(children: .combine)
    }

    private var medalColor: Color {
        switch ranked.rank {
        case 1: Palette.sun
        case 2: Color(red: 0.8, green: 0.84, blue: 0.9)
        case 3: Color(red: 1, green: 0.66, blue: 0.4)
        default: Palette.softCard
        }
    }
}

#Preview("Entries") {
    let store = InMemoryLeaderboardStore(entries: [
        LeaderboardEntry(playerName: "Andrew", score: 0.92),
        LeaderboardEntry(playerName: "Sam", score: 0.75),
        LeaderboardEntry(playerName: "Rina", score: 0.4),
    ])
    LeaderboardView(viewModel: LeaderboardViewModel(store: store))
}

#Preview("Empty") {
    LeaderboardView(viewModel: LeaderboardViewModel(store: InMemoryLeaderboardStore()))
}
