import SwiftUI

/// The left 2/3: an Edit/Explain toggle plus the code surface beneath it.
struct CodePanelView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Picker("", selection: Binding(
                    get: { model.mode },
                    set: { model.setMode($0) }
                )) {
                    Text("Edit").tag(AppModel.Mode.edit)
                    Text("Explain").tag(AppModel.Mode.explain)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 180)

                Text(model.mode == .edit
                     ? "Type or paste Python, then switch to Explain."
                     : "Hover to highlight · click for a definition · ⇧/⌘-click to multi-select · ←/→ to move")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if model.mode == .edit {
                SyntaxHighlightingTextView(text: $model.sourceText)
            } else {
                TermFlowView()
            }
        }
    }
}
