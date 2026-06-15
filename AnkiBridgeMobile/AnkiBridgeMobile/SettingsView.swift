import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings

    @State private var isTestingAnki = false
    @State private var ankiTestResult: String? = nil
    @State private var showPromptEditor = false
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                serverSection
                ankiConnectSection
                cardDefaultsSection
                systemPromptSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPromptEditor) {
                SystemPromptEditor()
            }
            .confirmationDialog(
                "Reset prompt to default?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    settings.resetPromptToDefault()
                }
            }
        }
    }

    // MARK: - Server Section

    private var serverSection: some View {
        Section {
            LabeledContent("Base URL") {
                TextField("http://host:1234/v1", text: $settings.serverBaseURL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
            }
            LabeledContent("API Key") {
                SecureField("Optional", text: $settings.apiKey)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
            }
            Button {
                Task { await appState.refreshModels() }
            } label: {
                HStack {
                    Label("Refresh Models", systemImage: "arrow.clockwise")
                    Spacer()
                    if appState.isLoadingModels {
                        ProgressView()
                    }
                }
            }
            .disabled(appState.isLoadingModels)

            if !appState.availableModels.isEmpty {
                Picker("Active Model", selection: $settings.selectedModel) {
                    ForEach(appState.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
            }
        } header: {
            Text("LLM Server")
        } footer: {
            Text("Any OpenAI-compatible server: LM Studio, Ollama, llama.cpp, vLLM, etc.")
        }
    }

    // MARK: - AnkiConnect Section

    private var ankiConnectSection: some View {
        Section {
            LabeledContent("URL") {
                TextField("http://host:8765", text: $settings.ankiConnectURL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
            }
            Button {
                Task { await testAnkiConnect() }
            } label: {
                HStack {
                    Label("Test Connection", systemImage: "network")
                    Spacer()
                    if isTestingAnki {
                        ProgressView()
                    } else if let result = ankiTestResult {
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(result.hasPrefix("✓") ? .green : .red)
                    }
                }
            }
            .disabled(isTestingAnki)
        } header: {
            Text("AnkiConnect")
        } footer: {
            Text("Install the AnkiConnect add-on in Anki on your desktop, then set the host to your computer's local IP address.")
        }
    }

    // MARK: - Card Defaults

    private var cardDefaultsSection: some View {
        Section("Card Defaults") {
            Picker("Default Card Type", selection: $settings.noteKind) {
                ForEach(NoteKind.allCases) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Context-Only Mode", isOn: $settings.constrainToContext)
        }
    }

    // MARK: - System Prompt

    private var systemPromptSection: some View {
        Section {
            Button {
                showPromptEditor = true
            } label: {
                HStack {
                    Label("Edit System Prompt", systemImage: "text.quote")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(.primary)

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset to Default", systemImage: "arrow.counterclockwise")
            }
        } header: {
            Text("System Prompt")
        } footer: {
            Text("Use {{noteKind}} as a placeholder for the current card type (Basic/Cloze).")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
            Link(destination: URL(string: "https://github.com/brueske/ankibridge")!) {
                Label("AnkiBridge on GitHub", systemImage: "safari")
            }
        }
    }

    // MARK: - Helpers

    private func testAnkiConnect() async {
        isTestingAnki = true
        ankiTestResult = nil
        defer { isTestingAnki = false }
        let client = AnkiConnectClient(baseURL: settings.ankiConnectURL)
        do {
            let version = try await client.version()
            ankiTestResult = "✓ API v\(version)"
        } catch {
            ankiTestResult = "✗ \(error.localizedDescription)"
        }
    }
}

// MARK: - SystemPromptEditor

struct SystemPromptEditor: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TextEditor(text: $settings.systemPromptTemplate)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .navigationTitle("System Prompt")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                            .fontWeight(.semibold)
                    }
                }
        }
    }
}
