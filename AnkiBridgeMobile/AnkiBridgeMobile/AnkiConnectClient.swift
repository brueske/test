import Foundation

// MARK: - AnkiConnectError

enum AnkiConnectError: Error, LocalizedError {
    case badURL
    case transportError(Error)
    case apiError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Invalid AnkiConnect URL."
        case .transportError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case .apiError(let message):
            return "AnkiConnect error: \(message)"
        case .decodingError:
            return "Failed to decode AnkiConnect response."
        }
    }
}

// MARK: - AnkiConnectClient

final class AnkiConnectClient {

    private let baseURL: String
    private let session: URLSession

    init(baseURL: String) {
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Private Helpers

    private func makeURL() throws -> URL {
        guard let url = URL(string: baseURL) else {
            throw AnkiConnectError.badURL
        }
        return url
    }

    /// Send a request envelope and decode the result as the given type.
    private func invoke<T: Decodable>(
        action: String,
        params: [String: Any] = [:]
    ) async throws -> T {
        let url = try makeURL()
        var requestBody: [String: Any] = [
            "action": action,
            "version": 6
        ]
        if !params.isEmpty {
            requestBody["params"] = params
        }

        let bodyData: Data
        do {
            bodyData = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw AnkiConnectError.transportError(error)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AnkiConnectError.transportError(error)
        }

        // AnkiConnect always returns HTTP 200, errors are in the body
        _ = response

        // Parse envelope: {"result": ..., "error": null | string}
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw AnkiConnectError.decodingError
        }

        if let errorMsg = json["error"] as? String {
            throw AnkiConnectError.apiError(errorMsg)
        }

        // Re-encode the "result" value so we can decode it as T
        guard let resultValue = json["result"] else {
            throw AnkiConnectError.decodingError
        }

        // Handle null result (some actions return null on success)
        if resultValue is NSNull {
            // Only valid if T is Optional or a type that can represent null
            if let optional = Optional<Any>.none as? T {
                return optional
            }
        }

        let resultData: Data
        do {
            resultData = try JSONSerialization.data(withJSONObject: resultValue)
        } catch {
            throw AnkiConnectError.decodingError
        }

        do {
            return try JSONDecoder().decode(T.self, from: resultData)
        } catch {
            throw AnkiConnectError.decodingError
        }
    }

    /// Variant for actions that return null or have no meaningful result (we only care about errors).
    private func invokeVoid(action: String, params: [String: Any] = []) async throws {
        let url = try makeURL()
        var requestBody: [String: Any] = [
            "action": action,
            "version": 6
        ]
        if !params.isEmpty {
            requestBody["params"] = params
        }

        let bodyData: Data
        do {
            bodyData = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw AnkiConnectError.transportError(error)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let data: Data
        do {
            (data, _) = try await session.data(for: request)
        } catch {
            throw AnkiConnectError.transportError(error)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AnkiConnectError.decodingError
        }
        if let errorMsg = json["error"] as? String {
            throw AnkiConnectError.apiError(errorMsg)
        }
    }

    // MARK: - Public API

    /// Returns the AnkiConnect API version (expect 6).
    func version() async throws -> Int {
        let result: Int = try await invoke(action: "version")
        return result
    }

    /// Returns all deck names.
    func deckNames() async throws -> [String] {
        let result: [String] = try await invoke(action: "deckNames")
        return result
    }

    /// Creates a deck by name; returns the deck ID.
    func createDeck(_ name: String) async throws -> Int64 {
        let result: Int64 = try await invoke(
            action: "createDeck",
            params: ["deck": name]
        )
        return result
    }

    /// Adds a note card to Anki; returns the new note ID.
    func addNote(_ card: NoteCard) async throws -> Int64 {
        var fields = card.ankiFields

        // Build picture list for image attachments
        var pictures: [[String: Any]] = []
        for (index, attachment) in card.imageAttachments.enumerated() {
            let fname = "ankibridge_\(card.id.uuidString)_\(index).\(attachment.fileExtension)"
            let fieldName: String
            switch card.kind {
            case .basic: fieldName = index == 0 ? "Front" : "Back"
            case .cloze: fieldName = "Text"
            }
            let pictureEntry: [String: Any] = [
                "data": attachment.base64,
                "filename": fname,
                "fields": [fieldName]
            ]
            pictures.append(pictureEntry)
        }

        var noteParams: [String: Any] = [
            "deckName": card.deck,
            "modelName": card.kind.ankiModelName,
            "fields": fields,
            "tags": card.tags,
            "options": [
                "allowDuplicate": false,
                "duplicateScope": "deck"
            ]
        ]
        if !pictures.isEmpty {
            noteParams["picture"] = pictures
        }

        let result: Int64 = try await invoke(
            action: "addNote",
            params: ["note": noteParams]
        )
        return result
    }

    /// Updates the fields of an existing note by ID.
    func updateNoteFields(id: Int64, fields: [String: String]) async throws {
        let noteParams: [String: Any] = [
            "id": id,
            "fields": fields
        ]
        try await invokeVoid(
            action: "updateNoteFields",
            params: ["note": noteParams]
        )
    }
}
