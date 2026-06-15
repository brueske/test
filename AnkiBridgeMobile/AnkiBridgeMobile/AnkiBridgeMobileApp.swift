import SwiftUI

@main
struct AnkiBridgeMobileApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(AppSettings.shared)
        }
    }
}
