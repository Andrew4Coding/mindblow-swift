import Foundation

nonisolated struct LeaderboardEntry: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let playerName: String
    let score: Double
    let date: Date

    init(id: UUID = UUID(), playerName: String, score: Double, date: Date = Date()) {
        self.id = id
        self.playerName = playerName
        self.score = score
        self.date = date
    }
}
