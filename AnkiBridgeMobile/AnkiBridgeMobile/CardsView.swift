import SwiftUI

struct CardsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings

    @State private var editingCard: NoteCard? = nil
    @State private var showDeleteConfirm = false
    @State private var pendingDeleteIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Group {
                if appState.cards.isEmpty {
                    emptyState
                } else {
                    cardList
                }
            }
            .navigationTitle("Cards (\(appState.cards.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(item: $editingCard) { card in
                CardEditorSheet(cardID: card.id)
            }
            .confirmationDialog(
                "Delete \(pendingDeleteIDs.count) card\(pendingDeleteIDs.count == 1 ? "" : "s")?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    appState.deleteCards(ids: pendingDeleteIDs)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No cards yet")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Chat with an AI model to generate flashcards, or add one manually.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Button {
                appState.addBlankCard()
            } label: {
                Label("Add Card", systemImage: "plus")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Card List

    private var cardList: some View {
        List {
            ForEach(appState.cards) { card in
                CardRow(card: card, isSelected: appState.selectedCardIDs.contains(card.id))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleSelection(card.id)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            pendingDeleteIDs = [card.id]
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            appState.duplicateCards(ids: [card.id])
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        .tint(.indigo)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            editingCard = card
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
            }
        }
        .listStyle(.plain)
        .safeAreaInset(edge: .bottom) {
            sendToAnkiBar
        }
    }

    // MARK: - Bottom Bar

    private var sendToAnkiBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                if !appState.selectedCardIDs.isEmpty {
                    Text("\(appState.selectedCardIDs.count) selected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                if appState.isSendingToAnki {
                    ProgressView()
                        .padding(.trailing, 4)
                } else {
                    Button {
                        let ids = appState.selectedCardIDs.isEmpty
                            ? Set(appState.cards.map(\.id))
                            : appState.selectedCardIDs
                        Task { await appState.sendToAnki(ids: ids) }
                    } label: {
                        Label(
                            appState.selectedCardIDs.isEmpty ? "Send All to Anki" : "Send Selected",
                            systemImage: "square.and.arrow.up"
                        )
                        .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(appState.cards.isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Button {
                    appState.selectedCardIDs = Set(appState.cards.map(\.id))
                } label: {
                    Label("Select All", systemImage: "checkmark.circle")
                }
                Button {
                    appState.selectedCardIDs = []
                } label: {
                    Label("Deselect All", systemImage: "circle")
                }
                Divider()
                Button(role: .destructive) {
                    if appState.selectedCardIDs.isEmpty {
                        pendingDeleteIDs = Set(appState.cards.map(\.id))
                    } else {
                        pendingDeleteIDs = appState.selectedCardIDs
                    }
                    showDeleteConfirm = true
                } label: {
                    Label("Delete Selected", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                appState.addBlankCard()
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    // MARK: - Helpers

    private func toggleSelection(_ id: UUID) {
        if appState.selectedCardIDs.contains(id) {
            appState.selectedCardIDs.remove(id)
        } else {
            appState.selectedCardIDs.insert(id)
        }
    }
}

// MARK: - CardRow

struct CardRow: View {
    let card: NoteCard
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .blue : .secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Label(card.kind.rawValue, systemImage: card.kind == .basic ? "rectangle.portrait" : "ellipsis.rectangle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if card.sentToAnki {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
                Text(card.title)
                    .lineLimit(2)
                    .font(.body)
                if !card.deck.isEmpty {
                    Text(card.deck)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()

            if !card.imageAttachments.isEmpty {
                Image(systemName: "photo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - CardEditorSheet

struct CardEditorSheet: View {
    let cardID: UUID
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var editDraft: NoteCard? = nil
    @State private var newTag = ""

    var body: some View {
        NavigationStack {
            Group {
                if let idx = appState.cards.firstIndex(where: { $0.id == cardID }) {
                    Form {
                        cardKindSection(idx: idx)
                        fieldsSection(idx: idx)
                        metadataSection(idx: idx)
                        tagsSection(idx: idx)
                    }
                } else {
                    Text("Card not found")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func cardKindSection(idx: Int) -> some View {
        Section("Card Type") {
            Picker("Type", selection: $appState.cards[idx].kind) {
                ForEach(NoteKind.allCases) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private func fieldsSection(idx: Int) -> some View {
        let card = appState.cards[idx]
        Section("Fields") {
            if card.kind == .basic {
                LabeledContent("Front") {
                    TextEditor(text: $appState.cards[idx].front)
                        .frame(minHeight: 80)
                }
                LabeledContent("Back") {
                    TextEditor(text: $appState.cards[idx].back)
                        .frame(minHeight: 80)
                }
            } else {
                LabeledContent("Text") {
                    TextEditor(text: $appState.cards[idx].clozeText)
                        .frame(minHeight: 80)
                }
            }
            LabeledContent("Extra") {
                TextEditor(text: $appState.cards[idx].extra)
                    .frame(minHeight: 60)
            }
        }
    }

    @ViewBuilder
    private func metadataSection(idx: Int) -> some View {
        Section("Deck") {
            TextField("Deck name", text: $appState.cards[idx].deck)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
    }

    @ViewBuilder
    private func tagsSection(idx: Int) -> some View {
        Section("Tags") {
            ForEach(appState.cards[idx].tags, id: \.self) { tag in
                Text(tag)
            }
            .onDelete { offsets in
                appState.cards[idx].tags.remove(atOffsets: offsets)
            }
            HStack {
                TextField("Add tag", text: $newTag)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit { addTag(idx: idx) }
                Button("Add") { addTag(idx: idx) }
                    .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func addTag(idx: Int) {
        let t = newTag.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, !appState.cards[idx].tags.contains(t) else { return }
        appState.cards[idx].tags.append(t)
        newTag = ""
    }
}
