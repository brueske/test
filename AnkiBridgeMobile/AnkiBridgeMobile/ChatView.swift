import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ChatView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings

    @State private var showPhotoPicker = false
    @State private var showDocumentPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var showModelPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messageList
                Divider()
                inputBar
            }
            .navigationTitle("AnkiBridge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    kindToggle
                }
                ToolbarItem(placement: .topBarTrailing) {
                    modelButton
                }
            }
            .sheet(isPresented: $showModelPicker) {
                ModelPickerSheet()
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItems, matching: .images)
        .onChange(of: selectedPhotoItems) { _, items in
            Task { await loadPhotos(items) }
        }
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.pdf, .plainText, .image],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                Task { await loadFiles(urls) }
            }
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(appState.messages) { msg in
                        if msg.role != .system {
                            MessageBubble(message: msg)
                                .id(msg.id)
                        }
                    }
                    if appState.isSending && appState.messages.last?.role == .user {
                        TypingIndicator()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .onAppear { scrollProxy = proxy }
            .onChange(of: appState.messages.count) { _, _ in
                scrollToBottom()
            }
            .onChange(of: appState.messages.last?.text) { _, _ in
                scrollToBottom()
            }
        }
    }

    private func scrollToBottom() {
        if let last = appState.messages.last {
            withAnimation(.easeOut(duration: 0.2)) {
                scrollProxy?.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            if !appState.pendingAttachments.isEmpty {
                attachmentStrip
            }
            HStack(alignment: .bottom, spacing: 8) {
                Menu {
                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label("Photo Library", systemImage: "photo")
                    }
                    Button {
                        showDocumentPicker = true
                    } label: {
                        Label("Files", systemImage: "doc")
                    }
                } label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                }

                TextField("Message...", text: $appState.draft, axis: .vertical)
                    .lineLimit(1...6)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .submitLabel(.return)

                Button {
                    Task { await appState.sendDraft() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(canSend ? .blue : .secondary)
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    private var canSend: Bool {
        !appState.isSending &&
        (!appState.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
         !appState.pendingAttachments.isEmpty)
    }

    // MARK: - Attachment Strip

    private var attachmentStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(appState.pendingAttachments) { att in
                    AttachmentChip(attachment: att) {
                        appState.removeAttachment(id: att.id)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Toolbar Items

    private var kindToggle: some View {
        Picker("Card Type", selection: $settings.noteKind) {
            ForEach(NoteKind.allCases) { kind in
                Text(kind.rawValue).tag(kind)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 130)
    }

    private var modelButton: some View {
        Button {
            showModelPicker = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "cpu")
                Text(settings.selectedModel.isEmpty ? "Model" : shortModelName(settings.selectedModel))
                    .font(.caption)
                    .lineLimit(1)
            }
        }
    }

    private func shortModelName(_ name: String) -> String {
        let parts = name.components(separatedBy: "/")
        return parts.last ?? name
    }

    // MARK: - Photo / File Loading

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let ext = (item.supportedContentTypes.first?.preferredFilenameExtension ?? "png").lowercased()
                let mime = ext == "jpg" || ext == "jpeg" ? "image/jpeg" : "image/\(ext)"
                let att = Attachment(id: UUID(), filename: "photo.\(ext)", data: data, mimeType: mime)
                appState.addAttachment(att)
            }
        }
        selectedPhotoItems = []
    }

    private func loadFiles(_ urls: [URL]) async {
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }
            if let att = try? Attachment.from(url: url) {
                appState.addAttachment(att)
            }
        }
    }
}

// MARK: - MessageBubble

struct MessageBubble: View {
    let message: ChatMessage
    @State private var showReasoning = false

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 48) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if let reasoning = message.reasoning, !reasoning.isEmpty {
                    DisclosureGroup("Reasoning", isExpanded: $showReasoning) {
                        Text(reasoning)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                if !message.attachments.isEmpty {
                    attachmentPreviews
                }

                if !message.text.isEmpty {
                    Text(message.text)
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(bubbleColor)
                        .foregroundStyle(textColor)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }

            if message.role != .user { Spacer(minLength: 48) }
        }
    }

    private var attachmentPreviews: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(message.attachments) { att in
                    if let img = att.uiImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Label(att.filename, systemImage: "doc")
                            .font(.caption)
                            .padding(6)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private var bubbleColor: Color {
        message.role == .user ? .blue : Color(.secondarySystemBackground)
    }

    private var textColor: Color {
        message.role == .user ? .white : .primary
    }
}

// MARK: - AttachmentChip

struct AttachmentChip: View {
    let attachment: Attachment
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            if let img = attachment.uiImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "doc.fill")
                    .font(.caption)
            }
            Text(attachment.filename)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 80)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }
}

// MARK: - TypingIndicator

struct TypingIndicator: View {
    @State private var phase = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundStyle(i == phase ? Color.primary : Color.secondary.opacity(0.4))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .frame(maxWidth: .infinity, alignment: .leading)
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}

// MARK: - ModelPickerSheet

struct ModelPickerSheet: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if appState.isLoadingModels {
                    ProgressView("Loading models…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if appState.availableModels.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "cpu.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No models available")
                            .foregroundStyle(.secondary)
                        Text("Check your server URL in Settings")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(appState.availableModels, id: \.self) { model in
                        Button {
                            settings.selectedModel = model
                            dismiss()
                        } label: {
                            HStack {
                                Text(model)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if model == settings.selectedModel {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await appState.refreshModels() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            if appState.availableModels.isEmpty {
                await appState.refreshModels()
            }
        }
    }
}
