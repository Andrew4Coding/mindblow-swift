import Foundation
import Observation

struct RankedEntry: Identifiable, Equatable {
    let rank: Int
    let entry: LeaderboardEntry

    var id: UUID { entry.id }
}

@Observable
final class LeaderboardViewModel {
    private(set) var rankedEntries: [RankedEntry] = []

    private let store: LeaderboardStoring

    init(store: LeaderboardStoring) {
        self.store = store
        load()
    }

    var isEmpty: Bool { rankedEntries.isEmpty }

    func load() {
        let sorted = store.entries().sorted {
            $0.score == $1.score ? $0.date < $1.date : $0.score > $1.score
        }
        rankedEntries = sorted.enumerated().map { RankedEntry(rank: $0.offset + 1, entry: $0.element) }
    }

    func clear() {
        store.removeAll()
        load()
    }
}
