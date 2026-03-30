import Foundation

enum ParameterType: String, Codable {
    case bool, string, int, float, path, color
    case `enum`
    case list
}

struct Parameter: Identifiable, Codable, Hashable {
    let id: String
    let key: String
    let type: ParameterType
    let defaultValue: String?
    let description: String
    let validValues: [String]?
    let since: String?
    let deprecated: Bool
    let deprecatedMessage: String?

    init(id: String, key: String, type: ParameterType, defaultValue: String? = nil,
         description: String, validValues: [String]? = nil, since: String? = nil,
         deprecated: Bool = false, deprecatedMessage: String? = nil) {
        self.id = id
        self.key = key
        self.type = type
        self.defaultValue = defaultValue
        self.description = description
        self.validValues = validValues
        self.since = since
        self.deprecated = deprecated
        self.deprecatedMessage = deprecatedMessage
    }
}
