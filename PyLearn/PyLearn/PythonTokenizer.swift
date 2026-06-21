import Foundation

/// A piece of a rendered line in Explain mode: either inert text (whitespace,
/// punctuation) or a selectable term referenced by its index in `terms`.
struct RenderCell: Identifiable {
    let id = UUID()
    enum Content {
        case gap(String)
        case term(Int)
    }
    let content: Content
}

struct RenderLine: Identifiable {
    let id = UUID()
    let cells: [RenderCell]
}

/// Result of analyzing source: the flat list of selectable terms plus a
/// line-by-line render model that preserves indentation/layout.
struct AnalysisResult {
    var terms: [Term]
    var lines: [RenderLine]
}

/// Hand-rolled Python lexer + a grouping pass that combines raw tokens into
/// learning-sized "terms" (e.g. a whole `print(...)` call becomes one term).
enum PythonTokenizer {

    // MARK: - Lexing

    static func tokenize(_ source: String) -> [Token] {
        var tokens: [Token] = []
        let chars = Array(source)
        var i = 0
        var loc = 0  // UTF-16 location

        func makeRange(_ s: String) -> NSRange {
            let r = NSRange(location: loc, length: (s as NSString).length)
            loc += r.length
            return r
        }

        func isIdentStart(_ c: Character) -> Bool { c == "_" || c.isLetter }
        func isIdentPart(_ c: Character) -> Bool { c == "_" || c.isLetter || c.isNumber }

        let multiCharOps = ["**=", "//=", ">>=", "<<=", "...", ":=", "->", "==",
                            "!=", "<=", ">=", "**", "//", "+=", "-=", "*=", "/=",
                            "%=", "&=", "|=", "^=", ">>", "<<"]
        let singleOps: Set<Character> = ["+", "-", "*", "/", "%", "<", ">", "=",
                                         "&", "|", "^", "~"]
        let punctuation: Set<Character> = ["(", ")", "[", "]", "{", "}", ",",
                                           ":", ".", "@", ";"]

        while i < chars.count {
            let c = chars[i]

            // Newline
            if c == "\n" {
                tokens.append(Token(text: "\n", kind: .newline, range: makeRange("\n")))
                i += 1
                continue
            }

            // Whitespace (spaces/tabs)
            if c == " " || c == "\t" || c == "\r" {
                var s = ""
                while i < chars.count, chars[i] == " " || chars[i] == "\t" || chars[i] == "\r" {
                    s.append(chars[i]); i += 1
                }
                tokens.append(Token(text: s, kind: .whitespace, range: makeRange(s)))
                continue
            }

            // Comment
            if c == "#" {
                var s = ""
                while i < chars.count, chars[i] != "\n" { s.append(chars[i]); i += 1 }
                tokens.append(Token(text: s, kind: .comment, range: makeRange(s)))
                continue
            }

            // String (with optional prefix like f, r, b, rb, fr ...)
            if c == "\"" || c == "'" || isStringPrefix(chars, i) {
                let (str, consumed) = scanString(chars, i)
                i += consumed
                tokens.append(Token(text: str, kind: .string, range: makeRange(str)))
                continue
            }

            // Number
            if c.isNumber || (c == "." && i + 1 < chars.count && chars[i + 1].isNumber) {
                var s = ""
                while i < chars.count {
                    let d = chars[i]
                    if d.isNumber || d == "." || d == "_" || d == "x" || d == "X"
                        || d == "o" || d == "O" || d == "b" || d == "B"
                        || d == "e" || d == "E" || d == "j" || d == "J"
                        || ((d == "+" || d == "-") && !s.isEmpty
                            && (s.last == "e" || s.last == "E"))
                        || (d.isHexDigit && s.lowercased().hasPrefix("0x")) {
                        s.append(d); i += 1
                    } else { break }
                }
                tokens.append(Token(text: s, kind: .number, range: makeRange(s)))
                continue
            }

            // Identifier / keyword / builtin
            if isIdentStart(c) {
                var s = ""
                while i < chars.count, isIdentPart(chars[i]) { s.append(chars[i]); i += 1 }
                let kind: TokenKind
                if PythonSyntax.keywords.contains(s) { kind = .keyword }
                else if PythonSyntax.builtins.contains(s) { kind = .builtin }
                else { kind = .identifier }
                tokens.append(Token(text: s, kind: kind, range: makeRange(s)))
                continue
            }

            // Multi-char operators
            if let op = matchMultiChar(chars, i, multiCharOps) {
                i += op.count
                tokens.append(Token(text: op, kind: .op, range: makeRange(op)))
                continue
            }

            // Single-char operators
            if singleOps.contains(c) {
                let s = String(c); i += 1
                tokens.append(Token(text: s, kind: .op, range: makeRange(s)))
                continue
            }

            // Punctuation
            if punctuation.contains(c) {
                let s = String(c); i += 1
                tokens.append(Token(text: s, kind: .punctuation, range: makeRange(s)))
                continue
            }

            // Anything else: emit as a lone whitespace-like gap so layout holds.
            let s = String(c); i += 1
            tokens.append(Token(text: s, kind: .punctuation, range: makeRange(s)))
        }

        return tokens
    }

    private static func isStringPrefix(_ chars: [Character], _ i: Int) -> Bool {
        // up to two prefix letters followed by a quote
        let prefixes: Set<Character> = ["f", "F", "r", "R", "b", "B", "u", "U"]
        var j = i
        var count = 0
        while j < chars.count, prefixes.contains(chars[j]), count < 2 { j += 1; count += 1 }
        return count > 0 && j < chars.count && (chars[j] == "\"" || chars[j] == "'")
    }

    /// Scans a string literal (single, double, or triple quoted) and returns
    /// the substring and how many characters were consumed.
    private static func scanString(_ chars: [Character], _ start: Int) -> (String, Int) {
        var i = start
        var s = ""
        // consume prefix letters
        let prefixes: Set<Character> = ["f", "F", "r", "R", "b", "B", "u", "U"]
        while i < chars.count, prefixes.contains(chars[i]) { s.append(chars[i]); i += 1 }
        guard i < chars.count else { return (s, i - start) }

        let quote = chars[i]
        // triple-quoted?
        let isTriple = i + 2 < chars.count && chars[i + 1] == quote && chars[i + 2] == quote
        if isTriple {
            s.append(chars[i]); s.append(chars[i + 1]); s.append(chars[i + 2])
            i += 3
            while i < chars.count {
                if chars[i] == quote,
                   i + 2 < chars.count,
                   chars[i + 1] == quote,
                   chars[i + 2] == quote {
                    s.append(chars[i]); s.append(chars[i + 1]); s.append(chars[i + 2])
                    i += 3
                    break
                }
                s.append(chars[i]); i += 1
            }
        } else {
            s.append(quote); i += 1
            while i < chars.count {
                let c = chars[i]
                if c == "\\", i + 1 < chars.count {
                    s.append(c); s.append(chars[i + 1]); i += 2; continue
                }
                s.append(c); i += 1
                if c == quote { break }
                if c == "\n" { break } // unterminated single-line string
            }
        }
        return (s, i - start)
    }

    private static func matchMultiChar(_ chars: [Character], _ i: Int, _ ops: [String]) -> String? {
        for op in ops {
            let arr = Array(op)
            if i + arr.count <= chars.count, Array(chars[i..<i + arr.count]) == arr {
                return op
            }
        }
        return nil
    }

    // MARK: - Grouping into terms + render lines

    static func analyze(_ source: String) -> AnalysisResult {
        let tokens = tokenize(source)
        var terms: [Term] = []
        var lines: [RenderLine] = []

        // split into lines on newline tokens
        var lineTokens: [Token] = []
        func flushLine() {
            let cells = groupLine(lineTokens, into: &terms)
            lines.append(RenderLine(cells: cells))
            lineTokens = []
        }

        for tok in tokens {
            if tok.kind == .newline { flushLine() }
            else { lineTokens.append(tok) }
        }
        flushLine()

        return AnalysisResult(terms: terms, lines: lines)
    }

    /// Groups one line's tokens into render cells, appending any new terms.
    private static func groupLine(_ lt: [Token], into terms: inout [Term]) -> [RenderCell] {
        var cells: [RenderCell] = []
        var i = 0

        func appendTerm(_ term: Term) {
            terms.append(term)
            cells.append(RenderCell(content: .term(terms.count - 1)))
        }

        while i < lt.count {
            let tok = lt[i]
            switch tok.kind {
            case .whitespace:
                cells.append(RenderCell(content: .gap(tok.text)))
                i += 1
            case .keyword:
                appendTerm(Term(text: tok.text, kind: .keyword, range: tok.range,
                                definitionKey: tok.text))
                i += 1
            case .number:
                appendTerm(Term(text: tok.text, kind: .number, range: tok.range,
                                definitionKey: "__number__"))
                i += 1
            case .string:
                appendTerm(Term(text: tok.text, kind: .string, range: tok.range,
                                definitionKey: "__string__"))
                i += 1
            case .comment:
                appendTerm(Term(text: tok.text, kind: .comment, range: tok.range,
                                definitionKey: "__comment__"))
                i += 1
            case .op:
                appendTerm(Term(text: tok.text, kind: .op, range: tok.range,
                                definitionKey: tok.text))
                i += 1
            case .identifier, .builtin:
                let (term, consumed) = collectPrimary(lt, i)
                appendTerm(term)
                i += consumed
            case .punctuation, .newline:
                cells.append(RenderCell(content: .gap(tok.text)))
                i += 1
            }
        }
        return cells
    }

    /// Starting at an identifier/builtin, collects an attribute/call chain that
    /// stays on this line and balances its brackets, e.g. `obj.method(args)`.
    private static func collectPrimary(_ lt: [Token], _ start: Int) -> (Term, Int) {
        var j = start
        var pieces: [Token] = [lt[j]]
        j += 1

        var hasCall = false
        var hasDot = false
        var lastFuncName = lt[start].text  // name immediately before first "("

        func skipToMatch(open: String, close: String) -> Bool {
            // lt[j] is the opening bracket
            var depth = 0
            while j < lt.count {
                let t = lt[j]
                pieces.append(t)
                if t.kind == .punctuation && t.text == open { depth += 1 }
                else if t.kind == .punctuation && t.text == close {
                    depth -= 1
                    if depth == 0 { j += 1; return true }
                }
                j += 1
            }
            return false
        }

        loop: while j < lt.count {
            let t = lt[j]
            if t.kind == .punctuation, t.text == "." ,
               j + 1 < lt.count, lt[j + 1].kind == .identifier || lt[j + 1].kind == .builtin {
                pieces.append(t)            // the dot
                pieces.append(lt[j + 1])    // the attribute name
                lastFuncName = lt[j + 1].text
                hasDot = true
                j += 2
            } else if t.kind == .punctuation, t.text == "(" {
                hasCall = true
                if !skipToMatch(open: "(", close: ")") { break loop }
            } else if t.kind == .punctuation, t.text == "[" {
                if !skipToMatch(open: "[", close: "]") { break loop }
            } else {
                break loop
            }
        }

        // Build combined text & range.
        let text = pieces.map { $0.text }.joined()
        let first = pieces.first!.range
        let last = pieces.last!.range
        let range = NSRange(location: first.location,
                            length: (last.location + last.length) - first.location)

        let kind: TermKind
        let key: String
        if hasCall {
            kind = .call
            key = PythonSyntax.builtins.contains(lastFuncName) ? lastFuncName : "__call__"
        } else if hasDot {
            kind = .attribute
            key = "__attribute__"
        } else {
            let name = pieces[0].text
            if PythonSyntax.builtins.contains(name) {
                kind = .builtin
                key = name
            } else {
                kind = .identifier
                key = "__identifier__"
            }
        }

        return (Term(text: text, kind: kind, range: range, definitionKey: key), j - start)
    }
}
