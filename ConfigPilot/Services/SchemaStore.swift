import Foundation
import SwiftData
import Combine

@MainActor
class SchemaStore: ObservableObject {
    @Published var tools: [Tool] = []
    @Published var loadedSchemas: [String: [ParameterSection]] = [:]

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadCatalog() {
        let descriptor = FetchDescriptor<ToolModel>(sortBy: [SortDescriptor(\.name)])
        guard let toolModels = try? modelContext.fetch(descriptor) else { return }
        tools = toolModels.map { $0.toValueType() }
    }

    func schema(for toolId: String) -> [ParameterSection]? {
        if let cached = loadedSchemas[toolId] {
            return cached
        }

        let descriptor = FetchDescriptor<ToolModel>(
            predicate: #Predicate<ToolModel> { tool in tool.toolID == toolId }
        )

        guard let toolModel = try? modelContext.fetch(descriptor).first else { return nil }

        let sections = toolModel.sortedSections().map { $0.toValueType() }
        loadedSchemas[toolId] = sections
        return sections
    }

    func searchParameters(query: String) -> [(Tool, Parameter)] {
        let lowered = query.lowercased()
        var results: [(Tool, Parameter)] = []

        for tool in tools {
            guard let sections = schema(for: tool.id) else { continue }
            for section in sections {
                for param in section.parameters {
                    if param.id.lowercased().contains(lowered) ||
                       param.description.lowercased().contains(lowered) ||
                       param.key.lowercased().contains(lowered) {
                        results.append((tool, param))
                    }
                }
            }
        }
        return results
    }

    func invalidateCache() {
        loadedSchemas.removeAll()
    }
}
