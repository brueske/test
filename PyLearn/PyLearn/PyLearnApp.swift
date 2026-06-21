import SwiftUI

@main
struct PyLearnApp: App {
    @StateObject private var model = AppModel()

    init() {
        AppSettings.registerDefaults()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 900, minHeight: 560)
        }
        .windowStyle(.titleBar)

        Settings {
            SettingsView()
        }
    }
}
