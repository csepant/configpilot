import Foundation

class ConfigScanner {
    private let fileManager = FileManager.default

    func scan(tool: Tool) -> [URL] {
        return tool.configPaths.compactMap { path in
            let expanded = NSString(string: path).expandingTildeInPath
            let url = URL(fileURLWithPath: expanded)
            return fileManager.fileExists(atPath: url.path) ? url : nil
        }
    }

    func scanAll(tools: [Tool]) -> [String: [URL]] {
        var results: [String: [URL]] = [:]
        for tool in tools {
            let found = scan(tool: tool)
            if !found.isEmpty {
                results[tool.id] = found
            }
        }
        return results
    }
}
