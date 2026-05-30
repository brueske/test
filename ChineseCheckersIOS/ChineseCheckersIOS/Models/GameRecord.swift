import Foundation

struct GameRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var winnerName: String
    var winnerEmoji: String
    var moves: Int
    var date: Date = Date()
}
