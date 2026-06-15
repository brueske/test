import Foundation

// MARK: - OpenAIClientError

enum OpenAIClientError: Error, LocalizedError {
    case badURL
    case httpError(Int, String)
    case decodingError
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Invalid server URL."
        case .httpError(let code, let body):
            return "HTTP \(code): \(body)"
        case .decodingError:
            return "Failed to decode server response."
        case .emptyResponse:
            return "The server returned an empty response."
        }
    }
}

// MARK: - OpenAIClient

final class OpenAIClient {

    private let baseURL: String
    private let apiKey: String
    private let session: URLSession

    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }

    // MARK: - Helpers

    private func makeRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw OpenAIClientError.badURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body
        return request
    }

    // MARK: - List Models

    func listModels() async throws -> [String] {
        let request = try makeRequest(path: "/models")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw OpenAIClientError.httpError(http.statusCode, body)
        }
        struct ModelList: Decodable {
            struct Model: Decodable { let id: String }
            let data: [Model]
        }
        guard let parsed = try? JSONDecoder().decode(ModelList.self, from: data) else {
            throw OpenAIClientError.decodingError
        }
        return parsed.data.map(\.id).sorted()
    }

    // MARK: - Build Message Payload

    private func buildMessagePayload(from messages: [ChatMessage]) -> [[String: Any]] {
        messages.map { msg in
            let roleStr = msg.role.rawValue
            if msg.attachments.isEmpty {
                return ["role": roleStr, "content": msg.text]
            }

            var parts: [[String: Any]] = []

            // Image attachments as image_url parts
            for attachment in msg.attachments where attachment.isImage {
                parts.append([
                    "type": "image_url",
                    "image_url": ["url": attachment.dataURL]
                ])
            }

            // Non-image attachments as text parts (embed content inline)
            for attachment in msg.attachments where !attachment.isImage {
                if let text = String(data: attachment.data, encoding: .utf8) {
                    parts.append([
                        "type": "text",
                        "text": "[\(attachment.filename)]\n\(text)"
                    ])
                }
            }

            // Main text part
            if !msg.text.isEmpty {
                parts.append([
                    "type": "text",
                    "text": msg.text
                ])
            }

            return ["role": roleStr, "content": parts]
        }
    }

    // MARK: - Stream Chat

    /// Streams a chat completion request.
    /// `onDelta` is async+Sendable so a `@MainActor` caller can annotate the closure
    /// to receive each chunk on the main actor without manual dispatch.
    func streamChat(
        messages: [ChatMessage],
        model: String,
        onDelta: @escaping @Sendable (String, String?) async -> Void
    ) async throws {
        let messagesPayload = buildMessagePayload(from: messages)

        let body: [String: Any] = [
            "model": model,
            "messages": messagesPayload,
            "stream": true,
            "stream_options": ["include_usage": false]
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            throw OpenAIClientError.decodingError
        }

        var request = try makeRequest(path: "/chat/completions", method: "POST", body: bodyData)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        let (byteStream, response) = try await session.bytes(for: request)

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            // Collect error body
            var errorData = Data()
            for try await byte in byteStream {
                errorData.append(byte)
                if errorData.count > 4096 { break }
            }
            let body = String(data: errorData, encoding: .utf8) ?? ""
            throw OpenAIClientError.httpError(http.statusCode, body)
        }

        var receivedContent = false

        for try await line in byteStream.lines {
            // SSE lines are prefixed with "data: "
            guard line.hasPrefix("data: ") else { continue }
            let jsonStr = String(line.dropFirst(6))
            guard jsonStr != "[DONE]" else { break }

            guard let data = jsonStr.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let delta = firstChoice["delta"] as? [String: Any]
            else { continue }

            let content = delta["content"] as? String ?? ""
            // Some providers use reasoning_content, others use reasoning
            let reasoning = (delta["reasoning_content"] as? String) ?? (delta["reasoning"] as? String)

            if !content.isEmpty || reasoning != nil {
                receivedContent = true
                await onDelta(content, reasoning)
            }
        }

        if !receivedContent {
            throw OpenAIClientError.emptyResponse
        }
    }
}
