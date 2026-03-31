import Foundation

final class LeaderboardManager {
    static let shared = LeaderboardManager()
    
    private let userDefaults: UserDefaults
    private let leaderboardKey = "LeaderboardEntries"
    
    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func saveEntry(_ entry: LeaderboardEntry) {
        var entries = getEntries()
        entries.append(entry)
        saveEntries(entries)
    }
    
    func getEntries() -> [LeaderboardEntry] {
        guard let data = userDefaults.data(forKey: leaderboardKey) else {
            return []
        }
        
        do {
            let entries = try JSONDecoder().decode([LeaderboardEntry].self, from: data)
            return entries
        } catch {
            print("Failed to decode leaderboard entries: \(error)")
            return []
        }
    }
    
    func getSortedEntries() -> [LeaderboardEntry] {
        return getEntries().sorted { $0.score > $1.score }
    }
    
    func clearLeaderboard() {
        userDefaults.removeObject(forKey: leaderboardKey)
    }
    
    private func saveEntries(_ entries: [LeaderboardEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            userDefaults.set(data, forKey: leaderboardKey)
        } catch {
            print("Failed to encode leaderboard entries: \(error)")
        }
    }
}
