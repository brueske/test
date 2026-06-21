import SwiftUI

/// Lower-right box: a model picker and an Analyze button that sends the
/// selected term(s) — or the whole script when nothing is selected — to the
/// chosen model for explanation.
struct LLMPanelView: View {
    @EnvironmentObject var model: AppModel
    @AppStorage(SettingsKey.provider) private var providerRaw = LLMProvider.claude.rawValue

    private var provider: Binding<LLMProvider> {
        Binding(
            get: { LLMProvider(rawValue: providerRaw) ?? .claude },
            set: { providerRaw = $0.rawValue }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Ask a Model")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Picker("Model", selection: provider) {
                        ForEach(LLMProvider.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 160)

                    Button(action: { model.runLLM() }) {
                        if model.isQuerying {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Analyze")
                        }
                    }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .disabled(model.isQuerying)

                    Spacer()
                }

                Text(selectionSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Divider()

                ScrollView {
                    if let err = model.llmError {
                        Text(err)
                            .font(.callout)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if model.llmOutput.isEmpty {
                        Text(model.isQuerying
                             ? "Thinking…"
                             : "Select term(s) on the left, or leave nothing selected to send the whole script, then press Analyze.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(model.llmOutput)
                            .font(.callout)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(12)
        }
    }

    private var selectionSummary: String {
        let sel = model.selectedText
        if sel.isEmpty { return "Nothing selected — will send the whole script." }
        return "Selected: \(sel)"
    }
}
