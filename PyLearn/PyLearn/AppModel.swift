import SwiftUI

/// Shared, observable state for the whole window.
@MainActor
final class AppModel: ObservableObject {

    enum Mode: String { case edit, explain }

    @Published var sourceText: String = AppModel.sampleCode
    @Published var mode: Mode = .edit

    // Explain-mode analysis
    @Published var terms: [Term] = []
    @Published var lines: [RenderLine] = []

    // Selection
    @Published var selectedIndices: Set<Int> = []   // for highlighting
    @Published var selectionOrder: [Int] = []       // ordered (for "puzzle" concatenation)
    @Published var focusIndex: Int? = nil           // drives the definition box & arrow nav
    @Published var hoveredIndex: Int? = nil

    // Definition box
    @Published var currentDefinition: Definition? = nil

    // LLM panel
    @Published var llmOutput: String = ""
    @Published var isQuerying: Bool = false
    @Published var llmError: String? = nil

    private var definitionTask: Task<Void, Never>?

    // MARK: - Mode switching

    func setMode(_ newMode: Mode) {
        if newMode == .explain { analyze() }
        else { clearSelection() }
        mode = newMode
    }

    func analyze() {
        let result = PythonTokenizer.analyze(sourceText)
        terms = result.terms
        lines = result.lines
        clearSelection()
    }

    // MARK: - Selection

    func clearSelection() {
        selectedIndices = []
        selectionOrder = []
        focusIndex = nil
        currentDefinition = nil
    }

    /// Plain click: select exactly this term.
    func selectSingle(_ i: Int) {
        guard terms.indices.contains(i) else { return }
        selectedIndices = [i]
        selectionOrder = [i]
        focusIndex = i
        updateDefinition(for: i)
    }

    /// Shift-click: select the contiguous range between the anchor and i.
    func extendSelection(to i: Int) {
        guard terms.indices.contains(i) else { return }
        let anchor = selectionOrder.first ?? focusIndex ?? i
        let lower = min(anchor, i)
        let upper = max(anchor, i)
        let range = Array(lower...upper)
        selectedIndices = Set(range)
        selectionOrder = range
        focusIndex = i
        updateDefinition(for: i)
    }

    /// Cmd-click: toggle this term as a discrete, order-preserving selection.
    func toggleSelection(_ i: Int) {
        guard terms.indices.contains(i) else { return }
        if selectedIndices.contains(i) {
            selectedIndices.remove(i)
            selectionOrder.removeAll { $0 == i }
        } else {
            selectedIndices.insert(i)
            selectionOrder.append(i)
        }
        focusIndex = i
        updateDefinition(for: i)
    }

    /// Arrow keys: move the single selection forward/backward through terms.
    func moveFocus(_ delta: Int) {
        guard !terms.isEmpty else { return }
        let current = focusIndex ?? (delta > 0 ? -1 : terms.count)
        var next = current + delta
        next = max(0, min(terms.count - 1, next))
        selectSingle(next)
    }

    /// The text sent to the LLM: ordered selected terms, or whole script.
    var selectedText: String {
        guard !selectionOrder.isEmpty else { return "" }
        return selectionOrder.map { terms[$0].text }.joined(separator: " ")
    }

    private func updateDefinition(for i: Int) {
        let term = terms[i]
        // Show the offline definition immediately, then refine if online is on.
        currentDefinition = DefinitionProvider.offline(key: term.definitionKey,
                                                       displayText: term.text)
        definitionTask?.cancel()
        let key = term.definitionKey
        let display = term.text
        definitionTask = Task { [weak self] in
            let resolved = await DefinitionProvider.resolve(key: key, displayText: display)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                // Only apply if the user hasn't moved on to another term.
                if self?.focusIndex == i { self?.currentDefinition = resolved }
            }
        }
    }

    // MARK: - LLM

    func runLLM() {
        guard !isQuerying else { return }
        isQuerying = true
        llmError = nil
        llmOutput = ""
        let selected = selectedText
        let full = sourceText
        Task { [weak self] in
            do {
                let result = try await LLMService.explain(selectedCode: selected, fullScript: full)
                await MainActor.run {
                    self?.llmOutput = result
                    self?.isQuerying = false
                }
            } catch {
                await MainActor.run {
                    self?.llmError = error.localizedDescription
                    self?.isQuerying = false
                }
            }
        }
    }

    // MARK: - Sample

    static let sampleCode = """
    # A simple Python example — switch to Explain mode and click a term.
    def greet(name):
        message = "Hello, " + name + "!"
        print(message)
        return len(message)

    for i in range(3):
        greet("World")
    """
}
