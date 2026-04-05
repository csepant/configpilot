import Foundation
import SwiftData

@Model
final class ToolModel {
    @Attribute(.unique) var toolID: String
    var name: String
    var categoryRaw: String
    var configPaths: [String]
    var configFormatRaw: String
    var schemaRef: String
    var iconName: String
    var isBuiltIn: Bool
    var schemaVersion: Int

    @Relationship(deleteRule: .cascade, inverse: \ParameterSectionModel.tool)
    var sections: [ParameterSectionModel]

    init(toolID: String, name: String, categoryRaw: String, configPaths: [String],
         configFormatRaw: String, schemaRef: String, iconName: String,
         isBuiltIn: Bool = true, schemaVersion: Int = 1) {
        self.toolID = toolID
        self.name = name
        self.categoryRaw = categoryRaw
        self.configPaths = configPaths
        self.configFormatRaw = configFormatRaw
        self.schemaRef = schemaRef
        self.iconName = iconName
        self.isBuiltIn = isBuiltIn
        self.schemaVersion = schemaVersion
        self.sections = []
    }
}
