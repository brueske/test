import Foundation

enum LLMError: LocalizedError {
    case missingAPIKey
    case badURL
    case http(Int, String)
    case emptyResponse
    case decoding

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "No Claude API key set. Add one in Settings (⌘,)."
        case .badURL:        return "The configured endpoint URL is invalid."
        case .http(let code, let body):
            return "Request failed (HTTP \(code)).\n\(body)"
        case .emptyResponse: return "The model returned an empty response."
        case .decoding:      return "Could not understand the model's response."
        }
    }
}

/// Sends explanation prompts to either Claude's Messages API or a local
/// OpenAI-compatible server (Ollama, LM Studio, etc.).
enum LLMService {

    static func explain(selectedCode: String, fullScript: String) async throws -> String {
        let snippet = selectedCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = snippet.isEmpty ? fullScript : snippet

        let system = """
        You are a friendly Python tutor helping a learner read code. Explain \
        clearly and concisely, in plain language, what the given Python performs \
        and why. If a small fix or improvement is obvious, mention it briefly.
        """
        let user: String
        if snippet.isEmpty {
            user = "Explain what this Python script does:\n\n```python\n\(code)\n```"
        } else {
            user = """
            In the context of this full script:

            ```python
            \(fullScript)
            ```

            Explain the function of this selected portion:

            ```python
            \(code)
            ```
            """
        }

        switch AppSettings.provider {
        case .claude:
            return try await callClaude(system: system, user: user)
        case .local:
            return try await callLocalOpenAI(system: system, user: user)
        }
    }

    // MARK: - Claude (native Messages API)

    private static func callClaude(system: String, user: String) async throws -> String {
        let key = AppSettings.claudeAPIKey
        guard !key.isEmpty else { throw LLMError.missingAPIKey }
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw LLMError.badURL
        }

        let body: [String: Any] = [
            "model": AppSettings.claudeModel,
            "max_tokens": 1024,
            "system": system,
            "messages": [["role": "user", "content": user]],
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        try checkStatus(response, data)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            throw LLMError.decoding
        }
        let text = content.compactMap { block -> String? in
            (block["type"] as? String) == "text" ? block["text"] as? String : nil
        }.joined(separator: "\n")

        guard !text.isEmpty else { throw LLMError.emptyResponse }
        return text
    }

    // MARK: - Local (OpenAI-compatible chat completions)

    private static func callLocalOpenAI(system: String, user: String) async throws -> String {
        let base = AppSettings.localBaseURL.trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: base + "/chat/completions") else {
            throw LLMError.badURL
        }

        let body: [String: Any] = [
            "model": AppSettings.localModel,
            "stream": false,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user],
            ],
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        try checkStatus(response, data)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw LLMError.decoding
        }
        guard !text.isEmpty else { throw LLMError.emptyResponse }
        return text
    }

    private static func checkStatus(_ response: URLResponse, _ data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw LLMError.http(http.statusCode, String(body.prefix(500)))
        }
    }
}
