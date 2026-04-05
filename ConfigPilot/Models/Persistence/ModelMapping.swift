import Foundation

// MARK: - @Model → Value Type conversions

extension ToolModel {
    func toValueType() -> Tool {
        Tool(
            id: toolID,
            name: name,
            category: ToolCategory(rawValue: categoryRaw) ?? .cli,
            configPaths: configPaths,
            configFormat: ConfigFormat(rawValue: configFormatRaw) ?? .ini,
            schemaRef: schemaRef,
            iconName: iconName
        )
    }

    func sortedSections() -> [ParameterSectionModel] {
        sections.sorted { $0.sortOrder < $1.sortOrder }
    }
}

extension ParameterSectionModel {
    func toValueType() -> ParameterSection {
        ParameterSection(
            id: sectionID,
            name: name,
            description: sectionDescription,
            parameters: parameters.sorted { $0.sortOrder < $1.sortOrder }.map { $0.toValueType() }
        )
    }
}

extension ParameterModel {
    func toValueType() -> Parameter {
        Parameter(
            id: parameterID,
            key: key,
            type: ParameterType(rawValue: typeRaw) ?? .string,
            defaultValue: defaultValue,
            description: paramDescription,
            validValues: validValues,
            since: since,
            deprecated: deprecated,
            deprecatedMessage: deprecatedMessage
        )
    }
}

// MARK: - Value Type → @Model factories (for seeding)

extension ToolModel {
    static func from(tool: Tool, sections: [ParameterSection], schemaVersion: Int) -> ToolModel {
        let model = ToolModel(
            toolID: tool.id,
            name: tool.name,
            categoryRaw: tool.category.rawValue,
            configPaths: tool.configPaths,
            configFormatRaw: tool.configFormat.rawValue,
            schemaRef: tool.schemaRef,
            iconName: tool.iconName,
            isBuiltIn: true,
            schemaVersion: schemaVersion
        )

        for (sectionIndex, section) in sections.enumerated() {
            let sectionModel = ParameterSectionModel(
                compositeID: "\(tool.id):\(section.id)",
                sectionID: section.id,
                name: section.name,
                sectionDescription: section.description,
                sortOrder: sectionIndex
            )
            sectionModel.tool = model

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

            model.sections.append(sectionModel)
        }

        return model
    }
}
