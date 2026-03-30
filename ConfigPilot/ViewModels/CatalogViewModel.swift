import SwiftUI

@MainActor
class CatalogViewModel: ObservableObject {
    @Published var tools: [Tool] = []
    @Published var configFileCounts: [String: Int] = [:]

    private var schemaStore: SchemaStore?

    func load(schemaStore: SchemaStore, scanner: ConfigScanner) {
        self.schemaStore = schemaStore
        self.tools = schemaStore.tools

        let found = scanner.scanAll(tools: tools)
        for (id, urls) in found {
            configFileCounts[id] = urls.count
        }
    }

    func filteredTools(query: String) -> [Tool] {
        if query.isEmpty { return tools }
        let lowered = query.lowercased()
        return tools.filter {
            $0.name.lowercased().contains(lowered) ||
            $0.id.lowercased().contains(lowered)
        }
    }
}
