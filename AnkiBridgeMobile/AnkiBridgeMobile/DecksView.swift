import SwiftUI

struct DecksView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showNewDeckSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if appState.isLoadingDecks {
                    ProgressView("Loading decks…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if appState.deckTree.isEmpty {
                    emptyState
                } else {
                    deckTreeList
                }
            }
            .navigationTitle("Decks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showNewDeckSheet) {
                NewDeckSheet()
            }
            .task {
                if appState.deckTree.isEmpty {
                    await appState.refreshDecks()
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.2")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No decks found")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Connect to AnkiConnect in Settings to browse and manage your decks.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Button {
                Task { await appState.refreshDecks() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Deck Tree

    private var deckTreeList: some View {
        List(appState.deckTree, children: \.childrenOrNil) { node in
            DeckRow(
                node: node,
                isSelected: node.id == appState.selectedDeck
            )
            .contentShape(Rectangle())
            .onTapGesture {
                appState.selectedDeck = node.id
            }
        }
        .listStyle(.sidebar)
        .refreshable {
            await appState.refreshDecks()
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showNewDeckSheet = true
            } label: {
                Image(systemName: "plus")
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            Button {
                Task { await appState.refreshDecks() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(appState.isLoadingDecks)
        }
    }
}

// MARK: - DeckNode children helper

extension DeckNode {
    var childrenOrNil: [DeckNode]? {
        children.isEmpty ? nil : children
    }
}

// MARK: - DeckRow

struct DeckRow: View {
    let node: DeckNode
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: node.children.isEmpty ? "tray" : "tray.2")
                .foregroundStyle(isSelected ? .blue : .secondary)
            Text(node.name)
                .fontWeight(isSelected ? .semibold : .regular)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }
}

// MARK: - NewDeckSheet

struct NewDeckSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var deckName = ""
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Deck name (use :: for sub-decks)", text: $deckName)
                        .autocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit { createDeck() }
                } footer: {
                    Text("Use \"Parent::Child\" notation for nested decks.")
                }
            }
            .navigationTitle("New Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isCreating {
                        ProgressView()
                    } else {
                        Button("Create") { createDeck() }
                            .disabled(deckName.trimmingCharacters(in: .whitespaces).isEmpty)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    private func createDeck() {
        let name = deckName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        isCreating = true
        Task {
            await appState.createDeck(named: name)
            isCreating = false
            dismiss()
        }
    }
}
