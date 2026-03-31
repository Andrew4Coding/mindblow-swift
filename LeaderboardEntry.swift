import Foundation

struct LeaderboardEntry: Codable, Identifiable {
    let id: UUID
    let playerName: String
    let score: Double
    let date: Date

    init(playerName: String, score: Double) {
        self.id = UUID()
        self.playerName = playerName
        self.score = score
        self.date = Date()
    }
}
