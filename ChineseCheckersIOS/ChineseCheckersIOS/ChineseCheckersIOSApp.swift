import SwiftUI

@main
struct ChineseCheckersIOSApp: App {
    @StateObject private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: GameStore
    @State private var inGame        = false
    @State private var p1Name        = "Player 1"
    @State private var p2Name        = "Player 2"
    @State private var initialState: GameState? = nil

    private var p1Emoji: String { store.emoji(for: p1Name) }
    private var p2Emoji: String { store.emoji(for: p2Name) }

    var body: some View {
        if inGame {
            GameView(
                p1Name: p1Name,
                p2Name: p2Name,
                p1Emoji: p1Emoji,
                p2Emoji: p2Emoji,
                initialState: initialState,
                onMenu: { inGame = false; initialState = nil }
            )
        } else {
            MenuView(
                onNewGame: { p1, p2 in
                    p1Name = p1; p2Name = p2
                    store.ensureProfile(name: p1, emoji: "🔴")
                    store.ensureProfile(name: p2, emoji: "🔵")
                    store.clearSavedGame()
                    initialState = nil
                    inGame = true
                },
                onContinue: {
                    guard let saved = store.savedGame else { return }
                    p1Name = saved.p1Name
                    p2Name = saved.p2Name
                    initialState = saved.state
                    inGame = true
                }
            )
        }
    }
}
