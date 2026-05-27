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
    @AppStorage("cc_lastP1") private var p1Name = "Player 1"
    @AppStorage("cc_lastP2") private var p2Name = "Player 2"
    @State private var inGame = false

    var body: some View {
        if inGame {
            GameView(
                p1Name: p1Name,
                p2Name: p2Name,
                onWin: { name in
                    store.recordWin(for: name)
                },
                onMenu: {
                    inGame = false
                }
            )
        } else {
            MenuView(
                p1Name: $p1Name,
                p2Name: $p2Name,
                onPlay: {
                    store.ensureProfile(name: p1Name)
                    store.ensureProfile(name: p2Name)
                    inGame = true
                }
            )
        }
    }
}
