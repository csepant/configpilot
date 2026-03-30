import Foundation

class PromptBuilder {
    func buildPrompt(configState: ConfigState, schema: [ParameterSection]) -> String {
        var parts: [String] = []

        parts.append("Tool: \(configState.tool.name)")
        parts.append("")

        // Current config
        if !configState.setValues.isEmpty {
            parts.append("## Current Configuration")
            for value in configState.setValues {
                parts.append("  \(value.key) = \(value.rawValue)")
            }
            parts.append("")
        }

        // Unset parameters by section
        parts.append("## Available but Unset Parameters")
        for section in schema {
            let unsetInSection = section.parameters.filter { param in
                configState.unsetParameters.contains(where: { $0.id == param.id })
            }
            if !unsetInSection.isEmpty {
                parts.append("  [\(section.name)]")
                for param in unsetInSection {
                    parts.append("    \(param.id) (\(param.type.rawValue))")
                }
            }
        }
        parts.append("")

        // Validation errors
        if !configState.validationErrors.isEmpty {
            parts.append("## Validation Errors")
            for error in configState.validationErrors {
                parts.append("  \(error.parameter.id): \(error.message)")
            }
            parts.append("")
        }

        parts.append("Analyze this configuration and suggest improvements. Consider the user is on macOS.")

        return parts.joined(separator: "\n")
    }
}
