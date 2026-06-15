import Foundation
import UIKit

// MARK: - NoteKind

enum NoteKind: String, CaseIterable, Identifiable, Codable {
    case basic = "Basic"
    case cloze = "Cloze"
    var id: String { rawValue }
    var ankiModelName: String { rawValue }
}

// MARK: - ChatRole

enum ChatRole: String, Codable {
    case system, user, assistant
}

// MARK: - Attachment

struct Attachment: Identifiable {
    let id: UUID
    var filename: String
    var data: Data
    var mimeType: String

    var isImage: Bool { mimeType.hasPrefix("image/") }
    var uiImage: UIImage? { isImage ? UIImage(data: data) : nil }
    var base64: String { data.base64EncodedString() }
    var dataURL: String { "data:\(mimeType);base64,\(base64)" }

    var fileExtension: String {
        switch mimeType {
        case "image/jpeg": return "jpg"
        case "image/png":  return "png"
        case "image/gif":  return "gif"
        case "image/webp": return "webp"
        default:           return "bin"
        }
    }

    static func from(url: URL) throws -> Attachment {
        let data = try Data(contentsOf: url)
        let ext = url.pathExtension.lowercased()
        let mime: String
        switch ext {
        case "jpg", "jpeg": mime = "image/jpeg"
        case "png":          mime = "image/png"
        case "gif":          mime = "image/gif"
        case "webp":         mime = "image/webp"
        case "pdf":          mime = "application/pdf"
        case "txt":          mime = "text/plain"
        default:             mime = "application/octet-stream"
        }
        return Attachment(id: UUID(), filename: url.lastPathComponent, data: data, mimeType: mime)
    }

    static func from(image: UIImage) -> Attachment? {
        guard let data = image.pngData() else { return nil }
        return Attachment(id: UUID(), filename: "image.png", data: data, mimeType: "image/png")
    }
}

// MARK: - ChatMessage

struct ChatMessage: Identifiable {
    let id: UUID
    var role: ChatRole
    var text: String
    var reasoning: String?
    var model: String?
    var attachments: [Attachment]
    var date: Date

    init(role: ChatRole, text: String, reasoning: String? = nil,
         model: String? = nil, attachments: [Attachment] = []) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.reasoning = reasoning
        self.model = model
        self.attachments = attachments
        self.date = Date()
    }
}

// MARK: - NoteCard

struct NoteCard: Identifiable {
    let id: UUID
    var kind: NoteKind
    var front: String
    var back: String
    var clozeText: String
    var extra: String
    var tags: [String]
    var deck: String
    var imageAttachments: [Attachment]
    var sentToAnki: Bool
    var ankiNoteID: Int64?

    init(kind: NoteKind, front: String = "", back: String = "",
         clozeText: String = "", extra: String = "",
         tags: [String] = ["AI"], deck: String = "Default",
         imageAttachments: [Attachment] = []) {
        self.id = UUID()
        self.kind = kind
        self.front = front
        self.back = back
        self.clozeText = clozeText
        self.extra = extra
        self.tags = tags
        self.deck = deck
        self.imageAttachments = imageAttachments
        self.sentToAnki = false
        self.ankiNoteID = nil
    }

    var title: String {
        let raw = kind == .cloze ? clozeText : front
        return stripped(raw)
    }

    private func stripped(_ s: String) -> String {
        var r = s
        r = r.replacingOccurrences(of: #"\{\{c\d+::(.*?)(::.*?)?\}\}"#, with: "$1", options: .regularExpression)
        r = r.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        r = r.replacingOccurrences(of: "&lt;", with: "<")
        r = r.replacingOccurrences(of: "&gt;", with: ">")
        r = r.replacingOccurrences(of: "&amp;", with: "&")
        r = r.replacingOccurrences(of: "&nbsp;", with: " ")
        let t = r.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "(empty)" : String(t.prefix(80))
    }

    var extraFieldName: String {
        switch kind {
        case .basic: return "Extra"
        case .cloze: return "Back Extra"
        }
    }

    var ankiFields: [String: String] {
        switch kind {
        case .basic: return ["Front": front, "Back": back, "Extra": extra]
        case .cloze: return ["Text": clozeText, "Back Extra": extra]
        }
    }
}

// MARK: - DeckNode

final class DeckNode: Identifiable, ObservableObject {
    let id: String
    var name: String
    var children: [DeckNode]

    init(id: String, name: String, children: [DeckNode] = []) {
        self.id = id
        self.name = name
        self.children = children
    }

    static func buildTree(from names: [String]) -> [DeckNode] {
        var lookup: [String: DeckNode] = [:]
        var roots: [DeckNode] = []

        for fullName in names.sorted() {
            let parts = fullName.components(separatedBy: "::")
            for i in 0..<parts.count {
                let path = parts[0...i].joined(separator: "::")
                if lookup[path] != nil { continue }
                let node = DeckNode(id: path, name: parts[i])
                lookup[path] = node
                if i == 0 {
                    roots.append(node)
                } else {
                    let parentPath = parts[0..<i].joined(separator: "::")
                    lookup[parentPath]?.children.append(node)
                }
            }
        }
        return roots
    }
}
