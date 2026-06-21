import SwiftUI
import AppKit

/// Explain mode: renders the source as a grid of selectable term "chips" that
/// preserve the original layout. Hover highlights a chunk; clicking shows its
/// definition; ⇧/⌘-click multi-selects; arrow keys move between terms.
struct TermFlowView: View {
    @EnvironmentObject var model: AppModel
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(model.lines.enumerated()), id: \.element.id) { _, line in
                    HStack(spacing: 0) {
                        ForEach(line.cells) { cell in
                            cellView(cell)
                        }
                        // Keep empty lines from collapsing.
                        if line.cells.isEmpty { Text(" ").font(Self.font) }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .focusable()
        .focused($focused)
        .onMoveCommand { direction in
            switch direction {
            case .left, .up:    model.moveFocus(-1)
            case .right, .down: model.moveFocus(1)
            default: break
            }
        }
        .onAppear { focused = true }
    }

    @ViewBuilder
    private func cellView(_ cell: RenderCell) -> some View {
        switch cell.content {
        case .gap(let text):
            Text(text.isEmpty ? " " : text)
                .font(Self.font)
                .foregroundStyle(.secondary)
                .fixedSize()
        case .term(let index):
            TermChip(index: index)
                .environmentObject(model)
        }
    }

    static let font = Font.system(size: 13, design: .monospaced)
}

private struct TermChip: View {
    @EnvironmentObject var model: AppModel
    let index: Int

    var body: some View {
        let term = model.terms[index]
        let isSelected = model.selectedIndices.contains(index)
        let isHovered = model.hoveredIndex == index
        let isFocus = model.focusIndex == index

        Text(term.text)
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(PythonSyntax.color(for: term.kind).color)
            .padding(.horizontal, 1)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(background(isSelected: isSelected, isHovered: isHovered))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.accentColor.opacity(isFocus ? 0.9 : 0), lineWidth: 1)
            )
            .fixedSize()
            .contentShape(Rectangle())
            .onHover { hovering in
                model.hoveredIndex = hovering ? index : (model.hoveredIndex == index ? nil : model.hoveredIndex)
            }
            .onTapGesture { handleTap() }
    }

    private func background(isSelected: Bool, isHovered: Bool) -> Color {
        if isSelected { return Color.accentColor.opacity(0.30) }
        if isHovered  { return Color.accentColor.opacity(0.12) }
        return .clear
    }

    private func handleTap() {
        let flags = NSEvent.modifierFlags
        if flags.contains(.shift) {
            model.extendSelection(to: index)
        } else if flags.contains(.command) {
            model.toggleSelection(index)
        } else {
            model.selectSingle(index)
        }
    }
}
