import Foundation
import Observation

@Observable
final class SaveScoreViewModel {
    static let maxNameLength = 20

    let score: Double
    var playerName = "" {
        didSet {
            if playerName.count > Self.maxNameLength {
                playerName = String(playerName.prefix(Self.maxNameLength))
            }
        }
    }

    private let store: LeaderboardStoring
    private let onSaved: (LeaderboardEntry) -> Void

    init(score: Double, store: LeaderboardStoring, onSaved: @escaping (LeaderboardEntry) -> Void) {
        self.score = score
        self.store = store
        self.onSaved = onSaved
    }

    var scorePercent: Int { Int(score * 100) }
    private var trimmedName: String { playerName.trimmingCharacters(in: .whitespacesAndNewlines) }
    var canSave: Bool { !trimmedName.isEmpty }

    @discardableResult
    func save() -> LeaderboardEntry? {
        guard canSave else { return nil }
        let entry = LeaderboardEntry(playerName: trimmedName, score: score)
        store.add(entry)
        onSaved(entry)
        return entry
    }
}
