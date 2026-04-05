import Foundation
import SwiftData

@Model
final class ParameterSectionModel {
    @Attribute(.unique) var compositeID: String
    var sectionID: String
    var name: String
    var sectionDescription: String?
    var sortOrder: Int

    var tool: ToolModel?

    @Relationship(deleteRule: .cascade, inverse: \ParameterModel.section)
    var parameters: [ParameterModel]

    init(compositeID: String, sectionID: String, name: String,
         sectionDescription: String? = nil, sortOrder: Int) {
        self.compositeID = compositeID
        self.sectionID = sectionID
        self.name = name
        self.sectionDescription = sectionDescription
        self.sortOrder = sortOrder
        self.parameters = []
    }
}
