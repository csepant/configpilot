import Foundation

class SchemaLoader {
    private var cache: [String: (Tool, [ParameterSection])] = [:]

    struct SchemaFile: Codable {
        let tool: ToolSchema
        let sections: [ParameterSection]
    }

    struct ToolSchema: Codable {
        let id: String
        let name: String
        let category: String
        let configPaths: [String]
        let configFormat: String
        let iconName: String
    }

    func loadSchema(for toolId: String) throws -> (Tool, [ParameterSection]) {
        if let cached = cache[toolId] {
            return cached
        }

        // Try subdirectory first (SPM layout), then bundle root (Xcode layout)
        guard let url = Bundle.main.url(forResource: toolId, withExtension: "json", subdirectory: "Schemas")
                ?? Bundle.main.url(forResource: toolId, withExtension: "json") else {
            throw SchemaError.fileNotFound(toolId)
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let schemaFile = try decoder.decode(SchemaFile.self, from: data)

        let tool = Tool(
            id: schemaFile.tool.id,
            name: schemaFile.tool.name,
            category: ToolCategory(rawValue: schemaFile.tool.category) ?? .cli,
            configPaths: schemaFile.tool.configPaths,
            configFormat: ConfigFormat(rawValue: schemaFile.tool.configFormat) ?? .ini,
            schemaRef: "\(toolId).json",
            iconName: schemaFile.tool.iconName
        )

        let result = (tool, schemaFile.sections)
        cache[toolId] = result
        return result
    }

    func loadToolCatalog() -> [Tool] {
        let toolIds = ["git", "neovim", "tmux", "zsh", "alacritty", "ghostty", "starship"]
        return toolIds.compactMap { id in
            try? loadSchema(for: id).0
        }
    }

    func clearCache() {
        cache.removeAll()
    }
}

enum SchemaError: LocalizedError {
    case fileNotFound(String)
    case invalidFormat(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let id):
            return "Schema file not found for tool: \(id)"
        case .invalidFormat(let detail):
            return "Invalid schema format: \(detail)"
        }
    }
}
