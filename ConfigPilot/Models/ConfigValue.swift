import Foundation

struct ConfigValue: Identifiable, Hashable {
    var id: String { "\(key):\(sourceFile):\(lineNumber ?? 0)" }
    let key: String
    let rawValue: String
    let sourceFile: String
    let lineNumber: Int?
}
