import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var selectedTool: Tool?
    @Published var globalSearchQuery: String = ""

    let schemaStore = SchemaStore()
    let configScanner = ConfigScanner()

    func initialize() {
        schemaStore.loadCatalog()
    }
}
