import Foundation
import OSLog

protocol LeaderboardStoring: AnyObject {
    func entries() -> [LeaderboardEntry]
    func add(_ entry: LeaderboardEntry)
    func removeAll()
}

final class UserDefaultsLeaderboardStore: LeaderboardStoring {
    private let defaults: UserDefaults
    private let key = "LeaderboardEntries"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func entries() -> [LeaderboardEntry] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([LeaderboardEntry].self, from: data)
        } catch {
            AppLog.storage.error("Failed to decode leaderboard: \(error.localizedDescription)")
            return []
        }
    }

    func add(_ entry: LeaderboardEntry) {
        write(entries() + [entry])
    }

    func removeAll() {
        defaults.removeObject(forKey: key)
    }

    private func write(_ entries: [LeaderboardEntry]) {
        do {
            defaults.set(try JSONEncoder().encode(entries), forKey: key)
        } catch {
            AppLog.storage.error("Failed to encode leaderboard: \(error.localizedDescription)")
        }
    }
}
