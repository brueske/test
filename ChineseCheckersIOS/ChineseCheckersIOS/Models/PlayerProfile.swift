import Foundation

struct PlayerProfile: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var emoji: String = "😀"
    var wins: Int = 0
}
