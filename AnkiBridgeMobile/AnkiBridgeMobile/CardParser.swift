import Foundation

// MARK: - CardParser

enum CardParser {

    // MARK: - Public Interface

    /// Extracts Anki cards from LLM output.
    ///
    /// Looks for a fenced ` ```anki ` block first; falls back to ` ```json `.
    /// Returns the text with the matched block removed, plus the parsed cards.
    static func extract(from text: String) -> (cleanText: String, cards: [NoteCard]) {
        if let (range, json) = findFencedBlock(in: text, language: "anki") {
            let cards = parse(json: json)
            let clean = text.replacingCharacters(in: range, with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (clean, cards)
        }

        if let (range, json) = findFencedBlock(in: text, language: "json") {
            let cards = parse(json: json)
            if !cards.isEmpty {
                let clean = text.replacingCharacters(in: range, with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return (clean, cards)
            }
        }

        return (text, [])
    }

    // MARK: - Fenced Block Extraction

    /// Finds the first fenced block with the given language tag.
    /// Returns the range of the entire fence (including backtick delimiters) and the inner JSON string.
    private static func findFencedBlock(
        in text: String,
        language: String
    ) -> (Range<String.Index>, String)? {
        // Pattern: ```<language>\n<content>\n```
        // Allow optional whitespace after the language tag on the opening line.
        let pattern = "```\(language)[^\\n]*\\n([\\s\\S]*?)\\n?```"
        guard
            let regex = try? NSRegularExpression(pattern: pattern, options: []),
            let match = regex.firstMatch(
                in: text,
                options: [],
                range: NSRange(text.startIndex..., in: text)
            )
        else { return nil }

        let fullRange = Range(match.range, in: text)!
        let innerRange = Range(match.range(at: 1), in: text)!
        let inner = String(text[innerRange])
        return (fullRange, inner)
    }

    // MARK: - JSON Parsing

    /// Parses a JSON array of card objects into NoteCard values.
    private static func parse(json: String) -> [NoteCard] {
        let trimmed = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else { return [] }

        // Attempt to decode as a raw JSON array of dictionaries
        guard
            let array = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]]
        else { return [] }

        return array.compactMap { parseObject($0) }
    }

    /// Converts a single card dictionary into a NoteCard.
    private static func parseObject(_ obj: [String: Any]) -> NoteCard? {
        let typeStr = (obj["type"] as? String ?? "basic").lowercased()
        let extra = obj["extra"] as? String ?? ""

        switch typeStr {
        case "cloze":
            let text = obj["text"] as? String ?? ""
            guard !text.isEmpty else { return nil }
            return NoteCard(
                kind: .cloze,
                clozeText: text,
                extra: extra
            )
        default: // "basic" or unrecognised
            let front = obj["front"] as? String ?? ""
            let back  = obj["back"]  as? String ?? ""
            guard !front.isEmpty else { return nil }
            return NoteCard(
                kind: .basic,
                front: front,
                back: back,
                extra: extra
            )
        }
    }
}
