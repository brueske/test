import SwiftUI

struct MenuView: View {
    let onNewGame:  (String, String) -> Void
    let onContinue: () -> Void

    @EnvironmentObject private var store: GameStore
    @State private var showNewGame    = false
    @State private var showProfiles   = false
    @State private var showScoreboard = false

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Spacer().frame(height: 64)
                    Text("Chinese")
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(.textMain)
                    Text("Checkers")
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(.moveHint)
                    HStack(spacing: 8) {
                        Circle().fill(Color.p1).frame(width: 14, height: 14)
                        Circle().fill(Color.p2).frame(width: 14, height: 14)
                    }
                    .padding(.top, 6)
                }

                Spacer()

                VStack(spacing: 14) {
                    HomeMenuButton(title: "New Game",      icon: "play.fill",       color: .moveHint) { showNewGame = true }
                    HomeMenuButton(title: "Continue Game", icon: "arrow.clockwise", color: store.savedGame != nil ? .p2 : .boardLine) { onContinue() }
                        .opacity(store.savedGame != nil ? 1 : 0.5)
                        .disabled(store.savedGame == nil)
                    HomeMenuButton(title: "Edit Profiles", icon: "person.2.fill",   color: .p1)       { showProfiles   = true }
                    HomeMenuButton(title: "Scoreboard",    icon: "trophy.fill",     color: .moveHint) { showScoreboard = true }
                }
                .padding(.horizontal, 28)

                Spacer()

                Text("2 Player Local")
                    .font(.system(size: 13))
                    .foregroundColor(.boardLine)
                    .padding(.bottom, 36)
            }
        }
        .sheet(isPresented: $showNewGame) {
            NewGameSheet { p1, p2 in showNewGame = false; onNewGame(p1, p2) }
        }
        .sheet(isPresented: $showProfiles)   { EditProfilesView() }
        .sheet(isPresented: $showScoreboard) { ScoreboardView() }
    }
}

// MARK: - Menu button row

private struct HomeMenuButton: View {
    let title:  String
    let icon:   String
    let color:  Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 28)
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textMain)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.boardLine)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: color.opacity(0.12), radius: 6, x: 0, y: 2)
        }
    }
}

// MARK: - New game sheet

private struct NewGameSheet: View {
    let onPlay: (String, String) -> Void

    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var p1 = ""
    @State private var p2 = ""
    @FocusState private var focus: Int?

    private var canPlay: Bool {
        let a = p1.trimmingCharacters(in: .whitespaces)
        let b = p2.trimmingCharacters(in: .whitespaces)
        return !a.isEmpty && !b.isEmpty && a.lowercased() != b.lowercased()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                VStack(spacing: 0) {
                    if !store.profiles.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Profiles")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(store.profiles) { profile in
                                        Button {
                                            if p1.isEmpty { p1 = profile.name }
                                            else if p2.isEmpty && profile.name.lowercased() != p1.lowercased() { p2 = profile.name }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Text(profile.emoji).font(.system(size: 18))
                                                Text(profile.name)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.textMain)
                                            }
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(Color.white, in: Capsule())
                                            .shadow(color: Color.boardLine.opacity(0.2), radius: 3, x: 0, y: 1)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 4)
                    }

                    VStack(spacing: 14) {
                        nameField(label: "Player 1", color: .p1, text: $p1, tag: 1, next: 2)
                        nameField(label: "Player 2", color: .p2, text: $p2, tag: 2, next: nil)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    Spacer()

                    Button {
                        onPlay(p1.trimmingCharacters(in: .whitespaces),
                               p2.trimmingCharacters(in: .whitespaces))
                    } label: {
                        Text("Play")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                canPlay
                                    ? LinearGradient(colors: [.p1, .moveHint], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [.boardLine, .boardLine], startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                    }
                    .disabled(!canPlay)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.moveHint)
                }
            }
            .onTapGesture { focus = nil }
        }
    }

    @ViewBuilder
    private func nameField(label: String, color: Color, text: Binding<String>, tag: Int, next: Int?) -> some View {
        HStack(spacing: 12) {
            Circle().fill(color).frame(width: 10, height: 10)
            TextField(label, text: text)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.textMain)
                .focused($focus, equals: tag)
                .submitLabel(next != nil ? .next : .done)
                .onSubmit { focus = next }
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(Color.white)
                .shadow(color: color.opacity(0.15), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(focus == tag ? color : Color.boardLine, lineWidth: 1.5)
        )
    }
}
