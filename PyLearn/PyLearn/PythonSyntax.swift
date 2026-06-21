import SwiftUI
import AppKit

/// Categories a raw token can fall into.
enum TokenKind {
    case keyword
    case builtin
    case identifier
    case number
    case string
    case comment
    case op          // operator, e.g. + == //
    case punctuation // ( ) [ ] { } , : . @
    case whitespace
    case newline
}

/// Semantic categories for a grouped, selectable term.
enum TermKind {
    case keyword
    case builtin
    case identifier
    case call        // a function/method call, e.g. print("hi")
    case attribute   // attribute access, e.g. math.pi
    case number
    case string
    case comment
    case op
}

/// A single lexical token with its location in the source (UTF-16 NSRange).
struct Token {
    var text: String
    var kind: TokenKind
    var range: NSRange
}

/// A grouped, selectable unit shown in Explain mode.
struct Term: Identifiable {
    let id = UUID()
    var text: String
    var kind: TermKind
    var range: NSRange
    /// Key used to look up a definition in `PythonDefinitions`.
    var definitionKey: String
}

/// Central place for Python keyword/builtin sets and the editor color theme.
enum PythonSyntax {

    static let keywords: Set<String> = [
        "False", "None", "True", "and", "as", "assert", "async", "await",
        "break", "class", "continue", "def", "del", "elif", "else", "except",
        "finally", "for", "from", "global", "if", "import", "in", "is",
        "lambda", "nonlocal", "not", "or", "pass", "raise", "return", "try",
        "while", "with", "yield", "match", "case"
    ]

    static let builtins: Set<String> = [
        "abs", "all", "any", "bin", "bool", "bytearray", "bytes", "callable",
        "chr", "classmethod", "complex", "dict", "dir", "divmod", "enumerate",
        "filter", "float", "format", "frozenset", "getattr", "hasattr", "hash",
        "hex", "id", "input", "int", "isinstance", "issubclass", "iter", "len",
        "list", "map", "max", "min", "next", "object", "oct", "open", "ord",
        "pow", "print", "range", "repr", "reversed", "round", "set", "setattr",
        "slice", "sorted", "staticmethod", "str", "sum", "super", "tuple",
        "type", "vars", "zip"
    ]

    // MARK: - Theme

    /// A color usable both in AppKit (NSColor) and SwiftUI (Color).
    struct PyColor {
        let light: (Double, Double, Double)
        let dark: (Double, Double, Double)

        var nsColor: NSColor {
            NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                let c = isDark ? dark : light
                return NSColor(srgbRed: c.0, green: c.1, blue: c.2, alpha: 1)
            }
        }

        var color: Color { Color(nsColor: nsColor) }
    }

    static let keywordColor   = PyColor(light: (0.61, 0.13, 0.58), dark: (0.84, 0.47, 0.86))
    static let builtinColor   = PyColor(light: (0.16, 0.34, 0.75), dark: (0.45, 0.62, 0.95))
    static let stringColor    = PyColor(light: (0.77, 0.18, 0.18), dark: (0.90, 0.49, 0.44))
    static let numberColor    = PyColor(light: (0.10, 0.43, 0.55), dark: (0.50, 0.78, 0.82))
    static let commentColor   = PyColor(light: (0.33, 0.50, 0.33), dark: (0.45, 0.60, 0.45))
    static let callColor      = PyColor(light: (0.20, 0.40, 0.70), dark: (0.49, 0.66, 0.96))
    static let identifierColor = PyColor(light: (0.10, 0.10, 0.12), dark: (0.86, 0.87, 0.90))
    static let operatorColor  = PyColor(light: (0.40, 0.40, 0.45), dark: (0.70, 0.72, 0.76))

    static func color(for kind: TokenKind) -> PyColor {
        switch kind {
        case .keyword:     return keywordColor
        case .builtin:     return builtinColor
        case .string:      return stringColor
        case .number:      return numberColor
        case .comment:     return commentColor
        case .op:          return operatorColor
        case .identifier, .punctuation, .whitespace, .newline:
            return identifierColor
        }
    }

    static func color(for kind: TermKind) -> PyColor {
        switch kind {
        case .keyword:    return keywordColor
        case .builtin:    return builtinColor
        case .call:       return callColor
        case .attribute:  return identifierColor
        case .number:     return numberColor
        case .string:     return stringColor
        case .comment:    return commentColor
        case .op:         return operatorColor
        case .identifier: return identifierColor
        }
    }
}
