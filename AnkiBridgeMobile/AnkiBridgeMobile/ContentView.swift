import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }

            CardsView()
                .tabItem {
                    Label("Cards", systemImage: "rectangle.stack.fill")
                }
                .badge(appState.cards.isEmpty ? 0 : appState.cards.count)

            DecksView()
                .tabItem {
                    Label("Decks", systemImage: "tray.2.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .alert("Error", isPresented: .init(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )) {
            Button("OK") { appState.errorMessage = nil }
        } message: {
            Text(appState.errorMessage ?? "")
        }
    }
}
