import SwiftUI

@MainActor
class DocsViewModel: ObservableObject {
    @Published var sections: [ParameterSection] = []
    @Published var expandedSections: Set<String> = []
    @Published var configValues: [String: ConfigValue] = [:]

    private let parser = ConfigParser()

    func load(tool: Tool, schemaStore: SchemaStore, scanner: ConfigScanner) {
        sections = schemaStore.schema(for: tool.id) ?? []
        expandedSections = Set(sections.map(\.id))

        // Load current config values
        configValues.removeAll()
        let files = scanner.scan(tool: tool)
        for file in files {
            if let values = try? parser.parse(file: file, format: tool.configFormat) {
                for value in values {
                    configValues[value.key] = value
                }
            }
        }
    }

    func filteredSections(query: String, deprecated: Bool) -> [ParameterSection] {
        let lowered = query.lowercased()

        return sections.compactMap { section in
            if query.isEmpty && !deprecated {
                return section
            }

            let filtered = section.parameters.filter { param in
                let matchesSearch = query.isEmpty ||
                    param.id.lowercased().contains(lowered) ||
                    param.key.lowercased().contains(lowered) ||
                    param.description.lowercased().contains(lowered)

                let matchesFilter = !deprecated || param.deprecated

                return matchesSearch && matchesFilter
            }

            if filtered.isEmpty { return nil }
            return ParameterSection(id: section.id, name: section.name, description: section.description, parameters: filtered)
        }
    }

    func isSectionExpanded(_ id: String) -> Bool {
        expandedSections.contains(id)
    }

    func toggleSection(_ id: String) {
        if expandedSections.contains(id) {
            expandedSections.remove(id)
        } else {
            expandedSections.insert(id)
        }
    }

    func configValue(for parameterId: String) -> ConfigValue? {
        configValues[parameterId]
    }
}
