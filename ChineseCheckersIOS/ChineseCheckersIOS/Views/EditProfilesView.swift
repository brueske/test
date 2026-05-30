import SwiftUI

struct EditProfilesView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var editingProfile: PlayerProfile? = nil
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                if store.profiles.isEmpty {
                    VStack(spacing: 16) {
                        Text("👤").font(.system(size: 48))
                        Text("No profiles yet")
                            .font(.system(size: 17)).foregroundColor(.secondary)
                        Button("Add Profile") { showAdd = true }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.moveHint)
                    }
                } else {
                    List {
                        ForEach(store.profiles) { profile in
                            ProfileRow(profile: profile) { editingProfile = profile }
                        }
                        .onDelete { store.deleteProfileAt($0.first!) }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.appBg)
                }
            }
            .navigationTitle("Edit Profiles")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }.foregroundColor(.moveHint)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus").foregroundColor(.moveHint)
                    }
                }
            }
            .sheet(item: $editingProfile) { EditProfileSheet(profile: $0) }
            .sheet(isPresented: $showAdd)  { AddProfileSheet() }
        }
    }
}

// MARK: - Profile row

private struct ProfileRow: View {
    let profile: PlayerProfile
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 14) {
                Text(profile.emoji)
                    .font(.system(size: 30))
                    .frame(width: 44, height: 44)
                    .background(Color.hole, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.textMain)
                    Text("\(profile.wins) win\(profile.wins == 1 ? "" : "s")")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(.boardLine)
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(Color.white)
    }
}

// MARK: - Edit profile sheet

private struct EditProfileSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let profile: PlayerProfile

    @State private var name  = ""
    @State private var emoji = ""
    @State private var showPicker = false

    private let emojiOptions = [
        "😀","😎","🤖","👻","🦊","🐱","🐻","🐼","🐸","🦄",
        "🐉","⭐","🔥","💫","🎮","🏆","🌈","💎","🚀","🎯",
        "🍀","🎲","👑","🌟","💥","🎨","🦁","🐯","🐺","🦅"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Emoji avatar button
                        Button { withAnimation { showPicker.toggle() } } label: {
                            Text(emoji)
                                .font(.system(size: 60))
                                .frame(width: 96, height: 96)
                                .background(Color.hole, in: Circle())
                                .overlay(Circle().stroke(Color.moveHint, lineWidth: 2))
                        }
                        .padding(.top, 28)

                        // Emoji picker grid
                        if showPicker {
                            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6), spacing: 12) {
                                ForEach(emojiOptions, id: \.self) { e in
                                    Button {
                                        emoji = e
                                        withAnimation { showPicker = false }
                                    } label: {
                                        Text(e).font(.system(size: 28))
                                            .frame(width: 44, height: 44)
                                            .background(
                                                emoji == e ? Color.moveHint.opacity(0.18) : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 8)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        // Name field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            TextField("Player name", text: $name)
                                .font(.system(size: 17))
                                .padding(14)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.boardLine, lineWidth: 1))
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.moveHint)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        store.updateProfile(id: profile.id, name: name, emoji: emoji)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.moveHint)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { name = profile.name; emoji = profile.emoji }
        }
    }
}

// MARK: - Add profile sheet

private struct AddProfileSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    @State private var name  = ""
    @State private var emoji = "😀"
    @State private var showPicker = false

    private let emojiOptions = [
        "😀","😎","🤖","👻","🦊","🐱","🐻","🐼","🐸","🦄",
        "🐉","⭐","🔥","💫","🎮","🏆","🌈","💎","🚀","🎯",
        "🍀","🎲","👑","🌟","💥","🎨","🦁","🐯","🐺","🦅"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Button { withAnimation { showPicker.toggle() } } label: {
                            Text(emoji)
                                .font(.system(size: 60))
                                .frame(width: 96, height: 96)
                                .background(Color.hole, in: Circle())
                                .overlay(Circle().stroke(Color.moveHint, lineWidth: 2))
                        }
                        .padding(.top, 28)

                        if showPicker {
                            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6), spacing: 12) {
                                ForEach(emojiOptions, id: \.self) { e in
                                    Button {
                                        emoji = e
                                        withAnimation { showPicker = false }
                                    } label: {
                                        Text(e).font(.system(size: 28))
                                            .frame(width: 44, height: 44)
                                            .background(
                                                emoji == e ? Color.moveHint.opacity(0.18) : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 8)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            TextField("Player name", text: $name)
                                .font(.system(size: 17))
                                .padding(14)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.boardLine, lineWidth: 1))
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .navigationTitle("Add Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.moveHint)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        store.ensureProfile(name: name, emoji: emoji)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.moveHint)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
