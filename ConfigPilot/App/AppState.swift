import SwiftUI
import SwiftData

@MainActor
class AppState: ObservableObject {
    @Published var selectedTool: Tool?
    @Published var globalSearchQuery: String = ""
    @Published var parameterToAdd: Parameter?

    let schemaStore: SchemaStore
    let configScanner = ConfigScanner()
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.schemaStore = SchemaStore(modelContext: modelContext)
    }

    func initialize() {
        schemaStore.loadCatalog()
    }

    static func preview() -> AppState {
        let schema = Schema([ToolModel.self, ParameterSectionModel.self, ParameterModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        return AppState(modelContext: container.mainContext)
    }
}
