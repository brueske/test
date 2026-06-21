import SwiftUI

/// Preferences window (⌘,): API key, model names, endpoints, and the
/// definition source.
struct SettingsView: View {
    @AppStorage(SettingsKey.claudeAPIKey) private var claudeAPIKey = ""
    @AppStorage(SettingsKey.claudeModel) private var claudeModel = "claude-opus-4-8"
    @AppStorage(SettingsKey.localBaseURL) private var localBaseURL = "http://localhost:11434/v1"
    @AppStorage(SettingsKey.localModel) private var localModel = "llama3"
    @AppStorage(SettingsKey.definitionSource) private var definitionSourceRaw = DefinitionSourceMode.offline.rawValue
    @AppStorage(SettingsKey.onlineSource) private var onlineSourceRaw = OnlineDefinitionSource.pythonDocs.rawValue

    var body: some View {
        TabView {
            modelsTab
                .tabItem { Label("Models", systemImage: "cpu") }
            definitionsTab
                .tabItem { Label("Definitions", systemImage: "book") }
        }
        .frame(width: 480, height: 320)
    }

    private var modelsTab: some View {
        Form {
            Section("Claude API") {
                SecureField("API Key", text: $claudeAPIKey)
                    .textFieldStyle(.roundedBorder)
                TextField("Model", text: $claudeModel)
                    .textFieldStyle(.roundedBorder)
                Text("Your key is stored in this app's preferences and sent only to api.anthropic.com.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Local LLM (OpenAI-compatible)") {
                TextField("Base URL", text: $localBaseURL)
                    .textFieldStyle(.roundedBorder)
                TextField("Model", text: $localModel)
                    .textFieldStyle(.roundedBorder)
                Text("Works with Ollama (http://localhost:11434/v1) or LM Studio (http://localhost:1234/v1).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var definitionsTab: some View {
        Form {
            Section("Term Definitions") {
                Picker("Source", selection: $definitionSourceRaw) {
                    ForEach(DefinitionSourceMode.allCases) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                if definitionSourceRaw == DefinitionSourceMode.online.rawValue {
                    Picker("Online source", selection: $onlineSourceRaw) {
                        ForEach(OnlineDefinitionSource.allCases) { src in
                            Text(src.displayName).tag(src.rawValue)
                        }
                    }
                }
                Text("Built-in definitions always work offline. Online lookups are best-effort and fall back to the built-in text if unreachable.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
