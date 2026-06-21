import SwiftUI
import AppKit

/// An editable NSTextView that colorizes Python syntax live as you type, in a
/// Sublime/Xcode-like style.
struct SyntaxHighlightingTextView: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }

        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.allowsUndo = true
        textView.font = Self.font
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.string = text
        textView.backgroundColor = NSColor.textBackgroundColor

        // Keep long lines instead of wrapping, with horizontal scrolling.
        textView.isHorizontallyResizable = true
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.containerSize = NSSize(width: .greatestFiniteMagnitude,
                                                        height: .greatestFiniteMagnitude)
        textView.maxSize = NSSize(width: .greatestFiniteMagnitude,
                                  height: .greatestFiniteMagnitude)
        scrollView.hasHorizontalScroller = true

        context.coordinator.apply(highlighting: textView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            let selected = textView.selectedRange()
            textView.string = text
            context.coordinator.apply(highlighting: textView)
            textView.setSelectedRange(NSRange(location: min(selected.location, (text as NSString).length),
                                              length: 0))
        }
    }

    static let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

    final class Coordinator: NSObject, NSTextViewDelegate {
        let parent: SyntaxHighlightingTextView
        init(_ parent: SyntaxHighlightingTextView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            apply(highlighting: textView)
        }

        func apply(highlighting textView: NSTextView) {
            guard let storage = textView.textStorage else { return }
            let fullRange = NSRange(location: 0, length: storage.length)
            storage.beginEditing()
            storage.setAttributes([
                .font: SyntaxHighlightingTextView.font,
                .foregroundColor: PythonSyntax.identifierColor.nsColor,
            ], range: fullRange)

            for token in PythonTokenizer.tokenize(textView.string) {
                guard token.kind != .whitespace, token.kind != .newline else { continue }
                let color = PythonSyntax.color(for: token.kind).nsColor
                if NSMaxRange(token.range) <= storage.length {
                    storage.addAttribute(.foregroundColor, value: color, range: token.range)
                }
            }
            storage.endEditing()
        }
    }
}
