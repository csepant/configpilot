import Foundation

class ConfigWriter {
    /// Update an existing value in a config file at the given line number
    func updateValue(in fileURL: URL, at lineNumber: Int, key: String, newValue: String, format: ConfigFormat) throws {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        var lines = content.components(separatedBy: "\n")
        let lineIndex = lineNumber - 1

        guard lineIndex >= 0 && lineIndex < lines.count else {
            throw WriterError.lineOutOfRange
        }

        lines[lineIndex] = replaceLine(lines[lineIndex], key: key, newValue: newValue, format: format)
        let newContent = lines.joined(separator: "\n")
        try newContent.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Append a new key-value pair to a config file
    func appendValue(to fileURL: URL, key: String, value: String, section: String?, format: ConfigFormat) throws {
        var content = try String(contentsOf: fileURL, encoding: .utf8)

        let line = formatNewLine(key: key, value: value, section: section, format: format)

        if let section = section, !section.isEmpty {
            // Try to find the section and append within it
            if let insertionPoint = findSectionEnd(in: content, section: section, format: format) {
                let index = content.index(content.startIndex, offsetBy: insertionPoint)
                content.insert(contentsOf: "\n\(line)", at: index)
            } else {
                // Section doesn't exist, create it
                let sectionHeader = formatSectionHeader(section: section, format: format)
                content += "\n\n\(sectionHeader)\n\(line)"
            }
        } else {
            // No section, just append to end
            if !content.hasSuffix("\n") { content += "\n" }
            content += line + "\n"
        }

        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Create a config file with an initial value
    func createFile(at fileURL: URL, key: String, value: String, section: String?, format: ConfigFormat) throws {
        let fm = FileManager.default
        let dir = fileURL.deletingLastPathComponent()
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        var content = ""
        if let section = section, !section.isEmpty {
            content = formatSectionHeader(section: section, format: format) + "\n"
        }
        content += formatNewLine(key: key, value: value, section: section, format: format) + "\n"
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    // MARK: - Private

    private func replaceLine(_ line: String, key: String, newValue: String, format: ConfigFormat) -> String {
        switch format {
        case .ini:
            // Preserve indentation
            let indent = line.prefix(while: { $0 == "\t" || $0 == " " })
            let shortKey = key.components(separatedBy: ".").last ?? key
            return "\(indent)\(shortKey) = \(newValue)"

        case .toml:
            let shortKey = key.components(separatedBy: ".").last ?? key
            let quotedValue = needsQuoting(newValue, format: format) ? "\"\(newValue)\"" : newValue
            return "\(shortKey) = \(quotedValue)"

        case .keyvalue:
            return "\(key) = \(newValue)"

        case .lua:
            let parts = key.components(separatedBy: ".")
            guard parts.count >= 2 else { return line }
            let namespace = parts[0]
            let optKey = parts.dropFirst().joined(separator: ".")
            let luaValue = formatLuaValue(newValue)
            return "vim.\(namespace).\(optKey) = \(luaValue)"

        case .zshrc:
            if key.hasPrefix("export.") {
                let varName = String(key.dropFirst(7))
                return "export \(varName)=\"\(newValue)\""
            } else if key.hasPrefix("setopt.") {
                let option = String(key.dropFirst(7))
                return newValue == "true" ? "setopt \(option)" : "unsetopt \(option)"
            } else if key.hasPrefix("var.") {
                let varName = String(key.dropFirst(4))
                return "\(varName)=\(newValue)"
            }
            return "\(key)=\(newValue)"

        case .json, .yaml:
            return line // Not supported for line-level editing
        }
    }

    private func formatNewLine(key: String, value: String, section: String?, format: ConfigFormat) -> String {
        switch format {
        case .ini:
            let shortKey = key.components(separatedBy: ".").last ?? key
            return "\t\(shortKey) = \(value)"

        case .toml:
            let shortKey = key.components(separatedBy: ".").last ?? key
            let quotedValue = needsQuoting(value, format: format) ? "\"\(value)\"" : value
            return "\(shortKey) = \(quotedValue)"

        case .keyvalue:
            return "\(key) = \(value)"

        case .lua:
            let parts = key.components(separatedBy: ".")
            guard parts.count >= 2 else { return "-- \(key) = \(value)" }
            let namespace = parts[0]
            let optKey = parts.dropFirst().joined(separator: ".")
            let luaValue = formatLuaValue(value)
            return "vim.\(namespace).\(optKey) = \(luaValue)"

        case .zshrc:
            if key.hasPrefix("export.") {
                return "export \(String(key.dropFirst(7)))=\"\(value)\""
            } else if key.hasPrefix("setopt.") {
                let option = String(key.dropFirst(7))
                return value == "true" ? "setopt \(option)" : "unsetopt \(option)"
            } else if key.hasPrefix("var.") {
                return "\(String(key.dropFirst(4)))=\(value)"
            }
            return "\(key)=\(value)"

        case .json, .yaml:
            return ""
        }
    }

    private func formatSectionHeader(section: String, format: ConfigFormat) -> String {
        switch format {
        case .ini:
            return "[\(section)]"
        case .toml:
            return "[\(section)]"
        default:
            return ""
        }
    }

    private func findSectionEnd(in content: String, section: String, format: ConfigFormat) -> Int? {
        let lines = content.components(separatedBy: "\n")
        let sectionPattern = "\\[\\s*\(NSRegularExpression.escapedPattern(for: section))\\s*\\]"
        let sectionRegex = try? NSRegularExpression(pattern: sectionPattern, options: .caseInsensitive)

        var inSection = false
        var lastLineEndOffset = 0
        var currentOffset = 0

        for line in lines {
            let lineLength = line.utf8.count + 1 // +1 for newline
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if let regex = sectionRegex {
                let range = NSRange(trimmed.startIndex..., in: trimmed)
                if regex.firstMatch(in: trimmed, range: range) != nil {
                    if inSection {
                        return lastLineEndOffset
                    }
                    inSection = true
                }
            }

            if inSection && trimmed.hasPrefix("[") && !trimmed.isEmpty {
                if let regex = sectionRegex {
                    let range = NSRange(trimmed.startIndex..., in: trimmed)
                    if regex.firstMatch(in: trimmed, range: range) == nil {
                        return lastLineEndOffset
                    }
                }
            }

            if inSection && !trimmed.isEmpty && !trimmed.hasPrefix("#") && !trimmed.hasPrefix(";") {
                lastLineEndOffset = currentOffset + line.utf8.count
            }

            currentOffset += lineLength
        }

        if inSection {
            return lastLineEndOffset
        }

        return nil
    }

    private func formatLuaValue(_ value: String) -> String {
        if value == "true" || value == "false" { return value }
        if Int(value) != nil || Double(value) != nil { return value }
        return "\"\(value)\""
    }

    private func needsQuoting(_ value: String, format: ConfigFormat) -> Bool {
        if value == "true" || value == "false" { return false }
        if Int(value) != nil || Double(value) != nil { return false }
        return true
    }
}

enum WriterError: LocalizedError {
    case lineOutOfRange
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .lineOutOfRange: return "Line number out of range in config file"
        case .unsupportedFormat: return "This config format does not support direct editing"
        }
    }
}
