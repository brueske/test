import Foundation

final class GameStore: ObservableObject {
    @Published private(set) var profiles:    [PlayerProfile] = []
    @Published private(set) var gameHistory: [GameRecord]    = []
    @Published private(set) var savedGame:   SavedGameData?  = nil

    private let profilesKey = "cc_profiles"
    private let historyKey  = "cc_game_history"
    private let savedKey    = "cc_saved_game"

    init() { load() }

    var sorted: [PlayerProfile] { profiles.sorted { $0.wins > $1.wins } }

    // MARK: - Profiles

    func ensureProfile(name: String, emoji: String = "😀") {
        let t = name.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        if !profiles.contains(where: { $0.name.lowercased() == t.lowercased() }) {
            profiles.append(PlayerProfile(name: t, emoji: emoji))
            persistProfiles()
        }
    }

    func updateProfile(id: UUID, name: String, emoji: String) {
        guard let idx = profiles.firstIndex(where: { $0.id == id }) else { return }
        let t = name.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        profiles[idx].name  = t
        profiles[idx].emoji = emoji
        persistProfiles()
    }

    func deleteProfile(_ profile: PlayerProfile) {
        profiles.removeAll { $0.id == profile.id }
        persistProfiles()
    }

    func deleteProfileAt(_ index: Int) {
        guard profiles.indices.contains(index) else { return }
        profiles.remove(at: index)
        persistProfiles()
    }

    func recordWin(for name: String) {
        let t = name.trimmingCharacters(in: .whitespaces)
        if let idx = profiles.firstIndex(where: { $0.name.lowercased() == t.lowercased() }) {
            profiles[idx].wins += 1
        } else {
            profiles.append(PlayerProfile(name: t, wins: 1))
        }
        persistProfiles()
    }

    func emoji(for name: String) -> String {
        profiles.first { $0.name.lowercased() == name.lowercased() }?.emoji ?? "😀"
    }

    // MARK: - Game history

    func recordGame(winnerName: String, winnerEmoji: String, moves: Int) {
        let record = GameRecord(winnerName: winnerName, winnerEmoji: winnerEmoji, moves: moves)
        gameHistory.insert(record, at: 0)
        if gameHistory.count > 10 { gameHistory = Array(gameHistory.prefix(10)) }
        persistHistory()
    }

    // MARK: - Saved game

    func saveGame(state: GameState, p1Name: String, p2Name: String) {
        savedGame = SavedGameData(state: state, p1Name: p1Name, p2Name: p2Name)
        if let data = try? JSONEncoder().encode(savedGame) {
            UserDefaults.standard.set(data, forKey: savedKey)
        }
    }

    func clearSavedGame() {
        savedGame = nil
        UserDefaults.standard.removeObject(forKey: savedKey)
    }

    // MARK: - Persistence

    private func persistProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: profilesKey)
        }
    }

    private func persistHistory() {
        if let data = try? JSONEncoder().encode(gameHistory) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: profilesKey),
           let v = try? JSONDecoder().decode([PlayerProfile].self, from: d) { profiles = v }
        if let d = UserDefaults.standard.data(forKey: historyKey),
           let v = try? JSONDecoder().decode([GameRecord].self, from: d) { gameHistory = v }
        if let d = UserDefaults.standard.data(forKey: savedKey),
           let v = try? JSONDecoder().decode(SavedGameData.self, from: d) { savedGame = v }
    }
}
