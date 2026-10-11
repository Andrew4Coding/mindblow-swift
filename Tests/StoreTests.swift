import Foundation
import Testing

@testable import MindBlow

@MainActor
struct StoreTests {
    private func makeDefaults() -> UserDefaults {
        let name = "MindBlowTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func leaderboardStoreRoundTripsEntries() {
        let store = UserDefaultsLeaderboardStore(defaults: makeDefaults())
        #expect(store.entries().isEmpty)

        let entry = LeaderboardEntry(playerName: "Sam", score: 0.8)
        store.add(entry)
        #expect(store.entries() == [entry])

        store.removeAll()
        #expect(store.entries().isEmpty)
    }

    @Test func preferencesDefaultsAndPersistence() {
        let defaults = makeDefaults()
        let store = UserDefaultsPreferencesStore(defaults: defaults)
        #expect(store.highScore == 0)
        #expect(store.selectedSkin == .car)
        #expect(store.isMusicEnabled)
        #expect(store.isSoundEffectsEnabled)
        #expect(store.isHapticsEnabled)

        store.highScore = 0.7
        store.selectedSkin = .motor
        store.isMusicEnabled = false

        let reloaded = UserDefaultsPreferencesStore(defaults: defaults)
        #expect(reloaded.highScore == 0.7)
        #expect(reloaded.selectedSkin == .motor)
        #expect(!reloaded.isMusicEnabled)
    }

    @Test func leaderboardViewModelRanksByScoreThenDate() {
        let early = LeaderboardEntry(playerName: "Early", score: 0.5, date: Date(timeIntervalSince1970: 1))
        let late = LeaderboardEntry(playerName: "Late", score: 0.5, date: Date(timeIntervalSince1970: 2))
        let best = LeaderboardEntry(playerName: "Best", score: 0.9)
        let store = InMemoryLeaderboardStore(entries: [late, early, best])

        let viewModel = LeaderboardViewModel(store: store)
        #expect(viewModel.rankedEntries.map(\.entry.playerName) == ["Best", "Early", "Late"])
        #expect(viewModel.rankedEntries.map(\.rank) == [1, 2, 3])

        viewModel.clear()
        #expect(viewModel.isEmpty)
    }

    @Test func saveScoreTrimsAndValidatesName() {
        let store = InMemoryLeaderboardStore()
        var saved: LeaderboardEntry?
        let viewModel = SaveScoreViewModel(score: 0.6, store: store) { saved = $0 }

        #expect(!viewModel.canSave)
        viewModel.playerName = "   "
        #expect(viewModel.save() == nil)

        viewModel.playerName = "  Andrew  "
        #expect(viewModel.save()?.playerName == "Andrew")
        #expect(saved?.score == 0.6)
        #expect(store.entries().count == 1)
    }

    @Test func saveScoreLimitsNameLength() {
        let viewModel = SaveScoreViewModel(score: 0.6, store: InMemoryLeaderboardStore()) { _ in }
        viewModel.playerName = String(repeating: "a", count: 50)
        #expect(viewModel.playerName.count == SaveScoreViewModel.maxNameLength)
    }
}

struct TireSkinTests {
    @Test func everySkinHasUniquePersistedNameAndPositiveMultiplier() {
        let raw = TireSkin.allCases.map(\.rawValue)
        #expect(Set(raw).count == TireSkin.allCases.count)
        #expect(TireSkin.allCases.allSatisfy { $0.pumpMultiplier > 0 })
        #expect(TireSkin.allCases.count >= 6)
    }

    @Test func legacyPersistedSkinsStillDecode() throws {
        for legacy in ["\"Car\"", "\"Truck\"", "\"Motorcycle\""] {
            _ = try JSONDecoder().decode(TireSkin.self, from: Data(legacy.utf8))
        }
    }
}
