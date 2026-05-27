import Foundation

struct PlayerProfile: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var wins: Int = 0
}
