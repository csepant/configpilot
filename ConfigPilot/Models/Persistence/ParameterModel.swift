import Foundation
import SwiftData

@Model
final class ParameterModel {
    @Attribute(.unique) var compositeID: String
    var parameterID: String
    var key: String
    var typeRaw: String
    var defaultValue: String?
    var paramDescription: String
    var validValues: [String]?
    var since: String?
    var deprecated: Bool
    var deprecatedMessage: String?
    var sortOrder: Int
    var isUserModified: Bool

    var section: ParameterSectionModel?

    init(compositeID: String, parameterID: String, key: String, typeRaw: String,
         defaultValue: String? = nil, paramDescription: String,
         validValues: [String]? = nil, since: String? = nil,
         deprecated: Bool = false, deprecatedMessage: String? = nil,
         sortOrder: Int, isUserModified: Bool = false) {
        self.compositeID = compositeID
        self.parameterID = parameterID
        self.key = key
        self.typeRaw = typeRaw
        self.defaultValue = defaultValue
        self.paramDescription = paramDescription
        self.validValues = validValues
        self.since = since
        self.deprecated = deprecated
        self.deprecatedMessage = deprecatedMessage
        self.sortOrder = sortOrder
        self.isUserModified = isUserModified
    }
}
