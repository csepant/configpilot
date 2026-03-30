import SwiftUI
import SwiftData

@main
struct ConfigPilotApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    appState.initialize()
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 700)

        Settings {
            SettingsView()
        }
    }
}
