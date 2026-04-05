import Foundation
import SwiftData

class SchemaSeedService {
    static let currentSchemaVersion = 2

    private let modelContext: ModelContext
    private let loader = SchemaLoader()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func seedIfNeeded() throws {
        let descriptor = FetchDescriptor<ToolModel>()
        let existingTools = try modelContext.fetch(descriptor)

        if existingTools.isEmpty {
            try seedAllTools()
        } else {
            try updateBuiltInToolsIfNeeded(existing: existingTools)
        }
    }

    private func seedAllTools() throws {
        let toolIds = ["git", "neovim", "tmux", "zsh", "alacritty", "ghostty", "starship", "claude"]

        for toolId in toolIds {
            guard let (tool, sections) = try? loader.loadSchema(for: toolId) else { continue }
            let model = ToolModel.from(tool: tool, sections: sections, schemaVersion: Self.currentSchemaVersion)
            modelContext.insert(model)
        }

        try modelContext.save()
    }

    private func updateBuiltInToolsIfNeeded(existing: [ToolModel]) throws {
        var needsSave = false
        let existingIDs = Set(existing.map(\.toolID))
        let allToolIds = ["git", "neovim", "tmux", "zsh", "alacritty", "ghostty", "starship", "claude"]

        // Add any new tools not yet in the database
        for toolId in allToolIds where !existingIDs.contains(toolId) {
            guard let (tool, sections) = try? loader.loadSchema(for: toolId) else { continue }
            let model = ToolModel.from(tool: tool, sections: sections, schemaVersion: Self.currentSchemaVersion)
            modelContext.insert(model)
            needsSave = true
        }

        // Update existing built-in tools if schema version changed
        for toolModel in existing where toolModel.isBuiltIn && toolModel.schemaVersion < Self.currentSchemaVersion {
            guard let (tool, sections) = try? loader.loadSchema(for: toolModel.toolID) else { continue }

            // Delete old sections (cascade deletes parameters)
            for section in toolModel.sections {
                modelContext.delete(section)
            }
            toolModel.sections.removeAll()

            // Update tool fields
            toolModel.name = tool.name
            toolModel.categoryRaw = tool.category.rawValue
            toolModel.configPaths = tool.configPaths
            toolModel.configFormatRaw = tool.configFormat.rawValue
            toolModel.iconName = tool.iconName
            toolModel.schemaVersion = Self.currentSchemaVersion

            // Re-create sections and parameters
            for (sectionIndex, section) in sections.enumerated() {
                let sectionModel = ParameterSectionModel(
                    compositeID: "\(tool.id):\(section.id)",
                    sectionID: section.id,
                    name: section.name,
                    sectionDescription: section.description,
                    sortOrder: sectionIndex
                )
                sectionModel.tool = toolModel

                for (paramIndex, param) in section.parameters.enumerated() {
                    let paramModel = ParameterModel(
                        compositeID: "\(tool.id):\(param.id)",
                        parameterID: param.id,
                        key: param.key,
                        typeRaw: param.type.rawValue,
                        defaultValue: param.defaultValue,
                        paramDescription: param.description,
                        validValues: param.validValues,
                        since: param.since,
                        deprecated: param.deprecated,
                        deprecatedMessage: param.deprecatedMessage,
                        sortOrder: paramIndex
                    )
                    paramModel.section = sectionModel
                    sectionModel.parameters.append(paramModel)
                }

                toolModel.sections.append(sectionModel)
            }

            needsSave = true
        }

        if needsSave {
            try modelContext.save()
        }
    }
}
