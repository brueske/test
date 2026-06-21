import Foundation

/// UserDefaults keys and small enums shared between the settings UI and the
/// services that read configuration at runtime.
enum SettingsKey {
    static let provider          = "llm.provider"          // "local" | "claude"
    static let claudeAPIKey      = "claude.apiKey"
    static let claudeModel       = "claude.model"
    static let localBaseURL      = "local.baseURL"
    static let localModel        = "local.model"
    static let definitionSource  = "definitions.source"     // "offline" | "online"
    static let onlineSource      = "definitions.onlineSource" // identifier of source
}

enum LLMProvider: String, CaseIterable, Identifiable {
    case local
    case claude
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .local:  return "Local LLM"
        case .claude: return "Claude API"
        }
    }
}

enum DefinitionSourceMode: String, CaseIterable, Identifiable {
    case offline
    case online
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .offline: return "Built-in (offline)"
        case .online:  return "Fetch online"
        }
    }
}

/// Commonly used online documentation sources for definitions.
enum OnlineDefinitionSource: String, CaseIterable, Identifiable {
    case pythonDocs       // docs.python.org
    case devDocs          // devdocs.io mirror
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .pythonDocs: return "docs.python.org"
        case .devDocs:    return "devdocs.io"
        }
    }
}

/// Centralized typed access to the defaults with sensible fallbacks.
enum AppSettings {
    private static var defaults: UserDefaults { .standard }

    static func registerDefaults() {
        defaults.register(defaults: [
            SettingsKey.provider: LLMProvider.claude.rawValue,
            SettingsKey.claudeModel: "claude-opus-4-8",
            SettingsKey.localBaseURL: "http://localhost:11434/v1",
            SettingsKey.localModel: "llama3",
            SettingsKey.definitionSource: DefinitionSourceMode.offline.rawValue,
            SettingsKey.onlineSource: OnlineDefinitionSource.pythonDocs.rawValue,
        ])
    }

    static var provider: LLMProvider {
        LLMProvider(rawValue: defaults.string(forKey: SettingsKey.provider) ?? "") ?? .claude
    }
    static var claudeAPIKey: String { defaults.string(forKey: SettingsKey.claudeAPIKey) ?? "" }
    static var claudeModel: String { defaults.string(forKey: SettingsKey.claudeModel) ?? "claude-opus-4-8" }
    static var localBaseURL: String { defaults.string(forKey: SettingsKey.localBaseURL) ?? "http://localhost:11434/v1" }
    static var localModel: String { defaults.string(forKey: SettingsKey.localModel) ?? "llama3" }
    static var definitionMode: DefinitionSourceMode {
        DefinitionSourceMode(rawValue: defaults.string(forKey: SettingsKey.definitionSource) ?? "") ?? .offline
    }
    static var onlineSource: OnlineDefinitionSource {
        OnlineDefinitionSource(rawValue: defaults.string(forKey: SettingsKey.onlineSource) ?? "") ?? .pythonDocs
    }
}
