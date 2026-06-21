import Foundation

/// Resolves a term to a `Definition`, honoring the offline/online setting.
///
/// The built-in dictionary is always available. When the user opts into an
/// online source, this attempts a best-effort fetch and falls back to the
/// offline definition if the network is unavailable or parsing fails — so the
/// app keeps working without internet.
enum DefinitionProvider {

    /// Synchronous, always-available offline definition.
    static func offline(key: String, displayText: String) -> Definition {
        PythonDefinitions.lookup(key, displayText: displayText)
    }

    /// Optionally enrich a definition from an online source. Returns the online
    /// result when successful, otherwise the offline fallback passed in.
    static func resolve(key: String, displayText: String) async -> Definition {
        let base = offline(key: key, displayText: displayText)
        guard AppSettings.definitionMode == .online else { return base }

        // Only attempt online lookups for named keywords/builtins (not generic
        // categories like "__string__").
        guard !key.hasPrefix("__") else { return base }

        if let online = await fetchOnline(symbol: key, source: AppSettings.onlineSource) {
            return online
        }
        return base
    }

    private static func fetchOnline(symbol: String,
                                    source: OnlineDefinitionSource) async -> Definition? {
        let urlString: String
        switch source {
        case .pythonDocs:
            // Functions live on functions.html; keywords on reference pages.
            urlString = "https://docs.python.org/3/library/functions.html"
        case .devDocs:
            urlString = "https://devdocs.io/python~3/library/functions"
        }
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let html = String(data: data, encoding: .utf8) else { return nil }
            if let summary = extractSummary(for: symbol, fromHTML: html) {
                let base = offline(key: symbol, displayText: symbol)
                return Definition(term: symbol,
                                  category: base.category + " — \(source.displayName)",
                                  summary: summary,
                                  example: base.example)
            }
            return nil
        } catch {
            return nil
        }
    }

    /// Very small heuristic HTML scrape: find the function's definition block
    /// and pull the first sentence of its description. Best-effort only.
    private static func extractSummary(for symbol: String, fromHTML html: String) -> String? {
        guard let anchorRange = html.range(of: "id=\"\(symbol)\"")
                ?? html.range(of: "id=\"\(symbol).html\"") else { return nil }
        let after = html[anchorRange.upperBound...]
        guard let pStart = after.range(of: "<p>") else { return nil }
        let body = after[pStart.upperBound...]
        guard let pEnd = body.range(of: "</p>") else { return nil }
        let raw = String(body[..<pEnd.lowerBound])
        let text = stripTags(raw)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : String(trimmed.prefix(400))
    }

    private static func stripTags(_ s: String) -> String {
        var result = ""
        var inTag = false
        for ch in s {
            if ch == "<" { inTag = true }
            else if ch == ">" { inTag = false }
            else if !inTag { result.append(ch) }
        }
        return result
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&#8217;", with: "'")
            .replacingOccurrences(of: "\n", with: " ")
    }
}
