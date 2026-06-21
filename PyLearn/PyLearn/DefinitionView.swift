import SwiftUI

/// Upper-right box: the definition + example for the currently focused term.
/// Multi-selecting terms never shows more than one definition here.
struct DefinitionView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Definition")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if let def = model.currentDefinition {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(def.term)
                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        Text(def.category)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(def.summary)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)

                        if !def.example.isEmpty {
                            Text("Example")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                            Text(def.example)
                                .font(.system(size: 12, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(nsColor: .textBackgroundColor))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.2))
                                )
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "cursorarrow.click")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("Click a term in Explain mode\nto see its definition here.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
