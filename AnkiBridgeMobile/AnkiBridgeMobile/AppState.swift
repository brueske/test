import Foundation
import UIKit

@MainActor
final class AppState: ObservableObject {

    // MARK: - Settings

    let settings = AppSettings.shared

    // MARK: - Models / Decks

    @Published var availableModels: [String] = []
    @Published var isLoadingModels = false
    @Published var deckTree: [DeckNode] = []
    @Published var isLoadingDecks = false
    @Published var selectedDeck: String = UserDefaults.standard.string(forKey: "selectedDeck") ?? "Default" {
        didSet { UserDefaults.standard.set(selectedDeck, forKey: "selectedDeck") }
    }

    // MARK: - Chat

    @Published var messages: [ChatMessage] = []
    @Published var draft: String = ""
    @Published var isSending = false
    @Published var pendingAttachments: [Attachment] = []

    // MARK: - Cards

    @Published var cards: [NoteCard] = []
    @Published var selectedCardIDs: Set<UUID> = []
    @Published var isSendingToAnki = false

    // MARK: - Status

    @Published var statusMessage: String?
    @Published var errorMessage: String?

    // MARK: - API Clients

    private var openAIClient: OpenAIClient {
        OpenAIClient(baseURL: settings.serverBaseURL, apiKey: settings.apiKey)
    }
    private var ankiClient: AnkiConnectClient {
        AnkiConnectClient(baseURL: settings.ankiConnectURL)
    }

    // MARK: - Model Management

    func refreshModels() async {
        isLoadingModels = true
        defer { isLoadingModels = false }
        do {
            let models = try await openAIClient.listModels()
            availableModels = models
            if !models.isEmpty &&
               (settings.selectedModel.isEmpty || !models.contains(settings.selectedModel)) {
                settings.selectedModel = models[0]
            }
        } catch {
            errorMessage = "Failed to load models: \(error.localizedDescription)"
        }
    }

    // MARK: - Deck Management

    func refreshDecks() async {
        isLoadingDecks = true
        defer { isLoadingDecks = false }
        do {
            let names = try await ankiClient.deckNames()
            deckTree = DeckNode.buildTree(from: names)
        } catch {
            errorMessage = "Failed to load decks: \(error.localizedDescription)"
        }
    }

    func createDeck(named name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            _ = try await ankiClient.createDeck(trimmed)
            await refreshDecks()
        } catch {
            errorMessage = "Failed to create deck: \(error.localizedDescription)"
        }
    }

    // MARK: - Chat

    func sendDraft() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || !pendingAttachments.isEmpty else { return }
        guard !isSending else { return }

        let attachments = pendingAttachments
        pendingAttachments = []
        draft = ""
        isSending = true
        defer { isSending = false }

        let userMsg = ChatMessage(role: .user, text: text, attachments: attachments)
        messages.append(userMsg)

        var apiMessages: [ChatMessage] = []
        let systemText = effectiveSystemPrompt
        if !systemText.isEmpty {
            apiMessages.append(ChatMessage(role: .system, text: systemText))
        }
        apiMessages.append(contentsOf: messages)

        messages.append(ChatMessage(role: .assistant, text: ""))
        let lastIndex = messages.count - 1

        var assistantText = ""
        var assistantReasoning = ""

        do {
            try await openAIClient.streamChat(
                messages: apiMessages,
                model: settings.selectedModel,
                onDelta: { @MainActor [weak self] content, reasoning in
                    guard let self else { return }
                    assistantText += content
                    if let r = reasoning { assistantReasoning += r }
                    let visible = self.liveVisible(assistantText)
                    self.messages[lastIndex].text = visible
                    if !assistantReasoning.isEmpty {
                        self.messages[lastIndex].reasoning = assistantReasoning
                    }
                }
            )

            let (clean, newCards) = CardParser.extract(from: assistantText)
            messages[lastIndex].text = clean.trimmingCharacters(in: .whitespacesAndNewlines)
            messages[lastIndex].model = settings.selectedModel

            if !newCards.isEmpty {
                let turnImages = attachments.filter { $0.isImage }
                let tagged = newCards.map { card -> NoteCard in
                    var c = card
                    c.deck = selectedDeck
                    c.imageAttachments = turnImages
                    return c
                }
                cards.append(contentsOf: tagged)
                if selectedCardIDs.isEmpty, let first = tagged.first {
                    selectedCardIDs = [first.id]
                }
            }
        } catch {
            messages[lastIndex].text = "⚠️ \(error.localizedDescription)"
        }
    }

    private var effectiveSystemPrompt: String {
        var prompt = settings.systemPromptTemplate
            .replacingOccurrences(of: "{{noteKind}}", with: settings.noteKind.rawValue)
        if settings.constrainToContext {
            prompt += "\n\nOnly use information provided by the user in this conversation. Do not rely on prior knowledge."
        }
        return prompt
    }

    private func liveVisible(_ text: String) -> String {
        if let range = text.range(of: "```anki", options: .backwards) {
            let after = text[range.lowerBound...]
            if !after.contains("```\n") && !after.hasSuffix("```") {
                return String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return text
    }

    // MARK: - Attachment Management

    func addAttachment(_ attachment: Attachment) {
        pendingAttachments.append(attachment)
    }

    func removeAttachment(id: UUID) {
        pendingAttachments.removeAll { $0.id == id }
    }

    func addPastedImage(_ image: UIImage) {
        if let a = Attachment.from(image: image) {
            pendingAttachments.append(a)
        }
    }

    // MARK: - Card Editing

    func addBlankCard() {
        let card = NoteCard(kind: settings.noteKind, deck: selectedDeck)
        cards.append(card)
        selectedCardIDs = [card.id]
    }

    func deleteCards(ids: Set<UUID>) {
        cards.removeAll { ids.contains($0.id) }
        selectedCardIDs.subtract(ids)
    }

    func duplicateCards(ids: Set<UUID>) {
        let toDupe = cards.filter { ids.contains($0.id) }
        var copies: [NoteCard] = []
        for source in toDupe {
            let copy = NoteCard(
                kind: source.kind,
                front: source.front,
                back: source.back,
                clozeText: source.clozeText,
                extra: source.extra,
                tags: source.tags,
                deck: source.deck,
                imageAttachments: source.imageAttachments
            )
            copies.append(copy)
        }
        cards.append(contentsOf: copies)
        selectedCardIDs = Set(copies.map(\.id))
    }

    // MARK: - Anki Export

    func sendToAnki(ids: Set<UUID>) async {
        guard !ids.isEmpty else { return }
        isSendingToAnki = true
        defer { isSendingToAnki = false }

        var added = 0
        var updated = 0
        var failures: [String] = []

        for id in ids {
            guard let idx = cards.firstIndex(where: { $0.id == id }) else { continue }
            let card = cards[idx]

            do {
                _ = try await ankiClient.createDeck(card.deck)
            } catch {
                failures.append("Deck error '\(card.title)': \(error.localizedDescription)")
                continue
            }

            if let noteID = card.ankiNoteID {
                do {
                    try await ankiClient.updateNoteFields(id: noteID, fields: card.ankiFields)
                    updated += 1
                } catch {
                    failures.append("Update failed '\(card.title)': \(error.localizedDescription)")
                }
            } else {
                do {
                    let noteID = try await ankiClient.addNote(card)
                    cards[idx].ankiNoteID = noteID
                    cards[idx].sentToAnki = true
                    added += 1
                } catch {
                    failures.append("Add failed '\(card.title)': \(error.localizedDescription)")
                }
            }
        }

        var parts: [String] = []
        if added > 0 { parts.append("\(added) added") }
        if updated > 0 { parts.append("\(updated) updated") }
        if !parts.isEmpty { statusMessage = "Anki: \(parts.joined(separator: ", "))" }
        if !failures.isEmpty { errorMessage = failures.joined(separator: "\n") }
    }
}
