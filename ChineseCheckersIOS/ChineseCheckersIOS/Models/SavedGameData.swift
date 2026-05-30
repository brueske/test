import Foundation

struct SavedGameData: Codable {
    var state: GameState
    var p1Name: String
    var p2Name: String
    var savedAt: Date = Date()
}
