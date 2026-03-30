import Foundation
import Combine

@MainActor
class SchemaStore: ObservableObject {
    @Published var tools: [Tool] = []
    @Published var loadedSchemas: [String: [ParameterSection]] = [:]

    private let loader = SchemaLoader()

    func loadCatalog() {
        tools = loader.loadToolCatalog()
    }

    func schema(for toolId: String) -> [ParameterSection]? {
        if let cached = loadedSchemas[toolId] {
            return cached
        }

        do {
            let (_, sections) = try loader.loadSchema(for: toolId)
            loadedSchemas[toolId] = sections
            return sections
        } catch {
            print("Failed to load schema for \(toolId): \(error)")
            return nil
        }
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
}
