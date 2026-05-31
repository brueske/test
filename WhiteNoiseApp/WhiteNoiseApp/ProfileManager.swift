import Foundation

struct NoiseProfile: Codable, Identifiable {
    var id: UUID
    var name: String
    var bandGains: [Float]

    init(id: UUID = UUID(), name: String, bandGains: [Float]) {
        self.id = id
        self.name = name
        self.bandGains = bandGains
    }
}

class ProfileManager: ObservableObject {
    @Published var profiles: [NoiseProfile] = []

    private let storageKey = "NoiseProfiles"

    init() {
        load()
    }

    func save(name: String, bandGains: [Float]) {
        let profile = NoiseProfile(name: name, bandGains: bandGains)
        profiles.append(profile)
        persist()
    }

    func update(id: UUID, name: String) {
        if let idx = profiles.firstIndex(where: { $0.id == id }) {
            profiles[idx].name = name
            persist()
        }
    }

    func delete(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([NoiseProfile].self, from: data) else { return }
        profiles = decoded
    }
}
