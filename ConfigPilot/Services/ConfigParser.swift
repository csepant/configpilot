import Foundation

class ConfigParser {
    func parse(file: URL, format: ConfigFormat) throws -> [ConfigValue] {
        let content = try String(contentsOf: file, encoding: .utf8)
        let path = file.path

        switch format {
        case .ini:
            return parseINI(content: content, sourceFile: path)
        case .toml:
            return parseTOML(content: content, sourceFile: path)
        case .keyvalue:
            return parseKeyValue(content: content, sourceFile: path)
        case .lua:
            return parseLua(content: content, sourceFile: path)
        case .zshrc:
            return parseZshrc(content: content, sourceFile: path)
        case .json:
            return parseJSON(content: content, sourceFile: path)
        case .yaml:
            return parseYAML(content: content, sourceFile: path)
        }
    }

    // MARK: - INI Parser (git config, tmux)

    private func parseINI(content: String, sourceFile: String) -> [ConfigValue] {
        var values: [ConfigValue] = []
        var currentSection = ""
        let lines = content.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix(";") {
                continue
            }

            // Section header: [section] or [section "subsection"]
            if let sectionMatch = trimmed.range(of: #"^\[([^\]]+)\]"#, options: .regularExpression) {
                let raw = String(trimmed[sectionMatch]).dropFirst().dropLast()
                currentSection = String(raw)
                    .replacingOccurrences(of: "\"", with: "")
                    .replacingOccurrences(of: " ", with: ".")
                    .lowercased()
                continue
            }

            // Key = value
            if let eqIndex = trimmed.firstIndex(of: "=") {
                let key = trimmed[trimmed.startIndex..<eqIndex]
                    .trimmingCharacters(in: .whitespaces)
                    .lowercased()
                let value = trimmed[trimmed.index(after: eqIndex)...]
                    .trimmingCharacters(in: .whitespaces)

                let fullKey = currentSection.isEmpty ? key : "\(currentSection).\(key)"
                values.append(ConfigValue(
                    key: fullKey,
                    rawValue: value,
                    sourceFile: sourceFile,
                    lineNumber: index + 1
                ))
            }

            // tmux-style: set -g key value / set-option key value
            if trimmed.hasPrefix("set ") || trimmed.hasPrefix("set-option ") {
                let parts = trimmed.components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty && $0 != "-g" && $0 != "-s" }
                if parts.count >= 3 {
                    let key = parts[1]
                    let value = parts[2...].joined(separator: " ")
                    values.append(ConfigValue(
                    key: key,
                        rawValue: value,
                        sourceFile: sourceFile,
                        lineNumber: index + 1
                    ))
                }
            }
        }

        return values
    }

    // MARK: - TOML Parser

    private func parseTOML(content: String, sourceFile: String) -> [ConfigValue] {
        var values: [ConfigValue] = []
        var currentSection = ""
        let lines = content.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Section header: [section] or [section.subsection]
            if let match = trimmed.range(of: #"^\[([^\]]+)\]"#, options: .regularExpression) {
                currentSection = String(trimmed[match]).dropFirst().dropLast()
                    .trimmingCharacters(in: .whitespaces)
                continue
            }

            // Key = value
            if let eqIndex = trimmed.firstIndex(of: "=") {
                let key = trimmed[trimmed.startIndex..<eqIndex]
                    .trimmingCharacters(in: .whitespaces)
                var value = trimmed[trimmed.index(after: eqIndex)...]
                    .trimmingCharacters(in: .whitespaces)

                // Remove surrounding quotes
                if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
                   (value.hasPrefix("'") && value.hasSuffix("'")) {
                    value = String(value.dropFirst().dropLast())
                }

                let fullKey = currentSection.isEmpty ? key : "\(currentSection).\(key)"
                values.append(ConfigValue(
                    key: fullKey,
                    rawValue: value,
                    sourceFile: sourceFile,
                    lineNumber: index + 1
                ))
            }
        }

        return values
    }

    // MARK: - Key-Value Parser (ghostty)

    private func parseKeyValue(content: String, sourceFile: String) -> [ConfigValue] {
        var values: [ConfigValue] = []
        let lines = content.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            if let eqIndex = trimmed.firstIndex(of: "=") {
                let key = trimmed[trimmed.startIndex..<eqIndex]
                    .trimmingCharacters(in: .whitespaces)
                let value = trimmed[trimmed.index(after: eqIndex)...]
                    .trimmingCharacters(in: .whitespaces)

                values.append(ConfigValue(
                    key: key,
                    rawValue: value,
                    sourceFile: sourceFile,
                    lineNumber: index + 1
                ))
            }
        }

        return values
    }

    // MARK: - Lua Parser (neovim)

    private func parseLua(content: String, sourceFile: String) -> [ConfigValue] {
        var values: [ConfigValue] = []
        let lines = content.components(separatedBy: .newlines)

        // Patterns: vim.opt.X = Y, vim.o.X = Y, vim.g.X = Y, vim.wo.X = Y, vim.bo.X = Y
        let pattern = #"vim\.(opt|o|g|wo|bo)\.(\w+)\s*=\s*(.+)"#
        let regex = try? NSRegularExpression(pattern: pattern)

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty || trimmed.hasPrefix("--") {
                continue
            }

            if let regex = regex {
                let range = NSRange(trimmed.startIndex..., in: trimmed)
                if let match = regex.firstMatch(in: trimmed, range: range) {
                    let namespace = String(trimmed[Range(match.range(at: 1), in: trimmed)!])
                    let key = String(trimmed[Range(match.range(at: 2), in: trimmed)!])
                    var value = String(trimmed[Range(match.range(at: 3), in: trimmed)!])
                        .trimmingCharacters(in: .whitespaces)

                    // Remove trailing comments
                    if let commentIndex = value.range(of: " --") {
                        value = String(value[value.startIndex..<commentIndex.lowerBound])
                            .trimmingCharacters(in: .whitespaces)
                    }

                    // Remove surrounding quotes
                    if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
                       (value.hasPrefix("'") && value.hasSuffix("'")) {
                        value = String(value.dropFirst().dropLast())
                    }

                    let fullKey = "\(namespace).\(key)"
                    values.append(ConfigValue(
                    key: fullKey,
                        rawValue: value,
                        sourceFile: sourceFile,
                        lineNumber: index + 1
                    ))
                }
            }
        }

        return values
    }

    // MARK: - Zshrc Parser

    private func parseZshrc(content: String, sourceFile: String) -> [ConfigValue] {
        var values: [ConfigValue] = []
        let lines = content.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // export VAR=value
            if trimmed.hasPrefix("export ") {
                let rest = String(trimmed.dropFirst(7)).trimmingCharacters(in: .whitespaces)
                if let eqIndex = rest.firstIndex(of: "=") {
                    let key = String(rest[rest.startIndex..<eqIndex])
                    var value = String(rest[rest.index(after: eqIndex)...])
                    if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
                       (value.hasPrefix("'") && value.hasSuffix("'")) {
                        value = String(value.dropFirst().dropLast())
                    }
                    values.append(ConfigValue(
                    key: "export.\(key)",
                        rawValue: value,
                        sourceFile: sourceFile,
                        lineNumber: index + 1
                    ))
                }
                continue
            }

            // setopt OPTION
            if trimmed.hasPrefix("setopt ") {
                let option = String(trimmed.dropFirst(7)).trimmingCharacters(in: .whitespaces)
                values.append(ConfigValue(
                    key: "setopt.\(option)",
                    rawValue: "true",
                    sourceFile: sourceFile,
                    lineNumber: index + 1
                ))
                continue
            }

            // unsetopt OPTION
            if trimmed.hasPrefix("unsetopt ") {
                let option = String(trimmed.dropFirst(9)).trimmingCharacters(in: .whitespaces)
                values.append(ConfigValue(
                    key: "setopt.\(option)",
                    rawValue: "false",
                    sourceFile: sourceFile,
                    lineNumber: index + 1
                ))
                continue
            }

            // HISTSIZE=value (variable assignment without export)
            if let eqIndex = trimmed.firstIndex(of: "="),
               !trimmed.contains(" "),
               trimmed[trimmed.startIndex].isLetter || trimmed[trimmed.startIndex] == "_" {
                let key = String(trimmed[trimmed.startIndex..<eqIndex])
                var value = String(trimmed[trimmed.index(after: eqIndex)...])
                if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
                   (value.hasPrefix("'") && value.hasSuffix("'")) {
                    value = String(value.dropFirst().dropLast())
                }
                values.append(ConfigValue(
                    key: "var.\(key)",
                    rawValue: value,
                    sourceFile: sourceFile,
                    lineNumber: index + 1
                ))
                continue
            }

            // plugins=(...)
            if trimmed.hasPrefix("plugins=") {
                let value = String(trimmed.dropFirst(8))
                    .trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                    .trimmingCharacters(in: .whitespaces)
                values.append(ConfigValue(
                    key: "plugins",
                    rawValue: value,
                    sourceFile: sourceFile,
                    lineNumber: index + 1
                ))
                continue
            }
        }

        return values
    }

    // MARK: - JSON Parser

    private func parseJSON(content: String, sourceFile: String) -> [ConfigValue] {
        guard let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }
        return flattenJSON(json, prefix: "", sourceFile: sourceFile)
    }

    private func flattenJSON(_ dict: [String: Any], prefix: String, sourceFile: String) -> [ConfigValue] {
        var values: [ConfigValue] = []
        for (key, value) in dict {
            let fullKey = prefix.isEmpty ? key : "\(prefix).\(key)"
            if let nested = value as? [String: Any] {
                values.append(contentsOf: flattenJSON(nested, prefix: fullKey, sourceFile: sourceFile))
            } else {
                values.append(ConfigValue(
                    key: fullKey,
                    rawValue: "\(value)",
                    sourceFile: sourceFile,
                    lineNumber: nil
                ))
            }
        }
        return values
    }

    // MARK: - YAML Parser (basic)

    private func parseYAML(content: String, sourceFile: String) -> [ConfigValue] {
        var values: [ConfigValue] = []
        var keyStack: [(String, Int)] = []
        let lines = content.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            if line.trimmingCharacters(in: .whitespaces).isEmpty ||
               line.trimmingCharacters(in: .whitespaces).hasPrefix("#") {
                continue
            }

            let indent = line.prefix(while: { $0 == " " }).count

            // Remove deeper or equal indented keys from stack
            while let last = keyStack.last, last.1 >= indent {
                keyStack.removeLast()
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let colonIndex = trimmed.firstIndex(of: ":") {
                let key = String(trimmed[trimmed.startIndex..<colonIndex])
                    .trimmingCharacters(in: .whitespaces)
                let rest = String(trimmed[trimmed.index(after: colonIndex)...])
                    .trimmingCharacters(in: .whitespaces)

                if rest.isEmpty {
                    // Section header
                    keyStack.append((key, indent))
                } else {
                    let prefix = keyStack.map(\.0).joined(separator: ".")
                    let fullKey = prefix.isEmpty ? key : "\(prefix).\(key)"
                    values.append(ConfigValue(
                    key: fullKey,
                        rawValue: rest,
                        sourceFile: sourceFile,
                        lineNumber: index + 1
                    ))
                }
            }
        }

        return values
    }
}
