import Foundation

final class GameStore: ObservableObject {
    @Published private(set) var profiles: [PlayerProfile] = []

    private let key = "cc_profiles"

    init() { load() }

    var sorted: [PlayerProfile] { profiles.sorted { $0.wins > $1.wins } }

    func recordWin(for name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let idx = profiles.firstIndex(where: { $0.name.lowercased() == trimmed.lowercased() }) {
            profiles[idx].wins += 1
        } else {
            profiles.append(PlayerProfile(name: trimmed, wins: 1))
        }
        persist()
    }

    func ensureProfile(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if !profiles.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) {
            profiles.append(PlayerProfile(name: trimmed))
            persist()
        }
    }

    func deleteProfile(_ profile: PlayerProfile) {
        profiles.removeAll { $0.id == profile.id }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([PlayerProfile].self, from: data) else { return }
        profiles = decoded
    }
}
