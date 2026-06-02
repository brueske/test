import Foundation

struct NoiseProfile: Codable, Identifiable {
    var id: UUID
    var name: String
    var bandGains: [Float]
    var lfoStates: [LFOState]?  // nil for profiles saved before LFO support
    var isPinned: Bool

    init(id: UUID = UUID(), name: String, bandGains: [Float], lfoStates: [LFOState]? = nil, isPinned: Bool = false) {
        self.id = id
        self.name = name
        self.bandGains = bandGains
        self.lfoStates = lfoStates
        self.isPinned = isPinned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        bandGains = try container.decode([Float].self, forKey: .bandGains)
        lfoStates = try container.decodeIfPresent([LFOState].self, forKey: .lfoStates)
        isPinned = (try container.decodeIfPresent(Bool.self, forKey: .isPinned)) ?? false
    }
}

class ProfileManager: ObservableObject {
    @Published var profiles: [NoiseProfile] = []

    private let storageKey = "NoiseProfiles"

    init() {
        load()
    }

    func save(name: String, bandGains: [Float], lfoStates: [LFOState]) {
        let profile = NoiseProfile(name: name, bandGains: bandGains, lfoStates: lfoStates)
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

    func delete(id: UUID) {
        profiles.removeAll { $0.id == id }
        persist()
    }

    func togglePin(id: UUID) {
        if let idx = profiles.firstIndex(where: { $0.id == id }) {
            profiles[idx].isPinned.toggle()
            persist()
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        profiles.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    var pinnedProfiles: [NoiseProfile] {
        profiles.filter { $0.isPinned }
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
