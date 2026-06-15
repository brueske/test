import Foundation
import Combine

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let serverBaseURL         = "serverBaseURL"
        static let apiKey                = "apiKey"
        static let ankiConnectURL        = "ankiConnectURL"
        static let selectedModel         = "selectedModel"
        static let systemPromptTemplate  = "systemPromptTemplate"
        static let constrainToContext    = "constrainToContext"
        static let noteKind              = "noteKind"
    }

    @Published var serverBaseURL: String {
        didSet { defaults.set(serverBaseURL, forKey: Keys.serverBaseURL) }
    }
    @Published var apiKey: String {
        didSet { defaults.set(apiKey, forKey: Keys.apiKey) }
    }
    @Published var ankiConnectURL: String {
        didSet { defaults.set(ankiConnectURL, forKey: Keys.ankiConnectURL) }
    }
    @Published var selectedModel: String {
        didSet { defaults.set(selectedModel, forKey: Keys.selectedModel) }
    }
    @Published var systemPromptTemplate: String {
        didSet { defaults.set(systemPromptTemplate, forKey: Keys.systemPromptTemplate) }
    }
    @Published var constrainToContext: Bool {
        didSet { defaults.set(constrainToContext, forKey: Keys.constrainToContext) }
    }
    @Published var noteKind: NoteKind {
        didSet { defaults.set(noteKind.rawValue, forKey: Keys.noteKind) }
    }

    static let defaultSystemPrompt = """
You are AnkiBridge, an assistant that turns study material into Anki flashcards.

Start by asking one or two clarifying questions if needed (difficulty level, card focus, etc.). Once you have enough information, produce all cards together in a single ```anki block.

Card format rules:
- Use {{noteKind}} cards unless the user specifies otherwise.
- Basic card: {"type":"basic","front":"<question>","back":"<answer>","extra":"<optional>"}
- Cloze card: {"type":"cloze","text":"<sentence with {{c1::hidden}} deletions>","extra":"<optional>"}
- Always output an array even for a single card.
- Use minimal HTML only when it genuinely helps (e.g. <b>, <br>).
- Each card must be self-contained and testable in isolation.

Example output:
```anki
[
  {"type":"basic","front":"What is photosynthesis?","back":"The process by which plants convert sunlight into glucose."},
  {"type":"cloze","text":"Photosynthesis occurs in the {{c1::chloroplast}}."}
]
```
"""

    private init() {
        serverBaseURL = defaults.string(forKey: Keys.serverBaseURL) ?? "http://192.168.1.1:1234/v1"
        apiKey = defaults.string(forKey: Keys.apiKey) ?? ""
        ankiConnectURL = defaults.string(forKey: Keys.ankiConnectURL) ?? "http://192.168.1.1:8765"
        selectedModel = defaults.string(forKey: Keys.selectedModel) ?? ""
        systemPromptTemplate = defaults.string(forKey: Keys.systemPromptTemplate) ?? Self.defaultSystemPrompt
        constrainToContext = defaults.bool(forKey: Keys.constrainToContext)
        noteKind = NoteKind(rawValue: defaults.string(forKey: Keys.noteKind) ?? "") ?? .basic
    }

    func resetPromptToDefault() {
        systemPromptTemplate = Self.defaultSystemPrompt
    }
}
