import SwiftUI
import SwiftData

@main
struct ConfigPilotApp: App {
    let modelContainer: ModelContainer
    @StateObject private var appState: AppState

    init() {
        let schema = Schema([ToolModel.self, ParameterSectionModel.self, ParameterModel.self])
        let config = ModelConfiguration("ConfigPilot", isStoredInMemoryOnly: false)
        let container = try! ModelContainer(for: schema, configurations: [config])
        self.modelContainer = container

        let context = container.mainContext
        let seedService = SchemaSeedService(modelContext: context)
        do {
            try seedService.seedIfNeeded()
        } catch {
            print("[ConfigPilot] Seeding failed: \(error)")
            // Force re-seed: delete all and retry
            do {
                try context.delete(model: ParameterModel.self)
                try context.delete(model: ParameterSectionModel.self)
                try context.delete(model: ToolModel.self)
                try context.save()
                try seedService.seedIfNeeded()
            } catch {
                print("[ConfigPilot] Re-seed also failed: \(error)")
            }
        }

        // Verify seeding worked
        let count = (try? context.fetchCount(FetchDescriptor<ToolModel>())) ?? 0
        print("[ConfigPilot] Tools in database: \(count)")

        let state = AppState(modelContext: context)
        state.initialize()
        _appState = StateObject(wrappedValue: state)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .modelContainer(modelContainer)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 700)

        Settings {
            SettingsView()
        }
    }
}
