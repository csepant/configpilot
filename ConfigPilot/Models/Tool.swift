import Foundation

enum ToolCategory: String, Codable, CaseIterable {
    case cli = "CLI Tools"
    case devTool = "Dev Tools"
}

struct Tool: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: ToolCategory
    let configPaths: [String]
    let configFormat: ConfigFormat
    let schemaRef: String
    let iconName: String
}
