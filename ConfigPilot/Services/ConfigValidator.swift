import Foundation

class ConfigValidator {
    func validate(values: [ConfigValue], schema: [ParameterSection], tool: Tool) -> ConfigState {
        let allParameters = schema.flatMap(\.parameters)
        let paramsByKey = Dictionary(allParameters.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        var setValues: [ConfigValue] = []
        var validationErrors: [ValidationError] = []
        var overrideMap: [String: [ConfigValue]] = [:]

        // Group values by parameter id for override detection
        for value in values {
            overrideMap[value.key, default: []].append(value)
        }

        // Find overrides (same key set in multiple files)
        var overrides: [ConfigOverride] = []
        for (key, vals) in overrideMap where vals.count > 1 {
            if let param = paramsByKey[key] {
                overrides.append(ConfigOverride(parameter: param, values: vals))
            }
        }

        // Validate each value
        for value in values {
            setValues.append(value)

            guard let param = paramsByKey[value.key] else {
                continue // Unknown parameter, not in schema
            }

            // Type validation
            if let error = validateType(value: value, parameter: param) {
                validationErrors.append(error)
            }

            // Deprecated check
            if param.deprecated {
                validationErrors.append(ValidationError(
                    parameter: param,
                    value: value,
                    message: param.deprecatedMessage ?? "This parameter is deprecated"
                ))
            }
        }

        // Find unset parameters
        let setKeys = Set(values.map(\.key))
        let unsetParameters = allParameters.filter { !setKeys.contains($0.id) }

        return ConfigState(
            tool: tool,
            setValues: setValues,
            unsetParameters: unsetParameters,
            validationErrors: validationErrors,
            overrides: overrides
        )
    }

    private func validateType(value: ConfigValue, parameter: Parameter) -> ValidationError? {
        let raw = value.rawValue.lowercased()

        switch parameter.type {
        case .bool:
            let boolValues = ["true", "false", "yes", "no", "on", "off", "1", "0"]
            if !boolValues.contains(raw) {
                return ValidationError(
                    parameter: parameter,
                    value: value,
                    message: "Expected bool, got '\(value.rawValue)'"
                )
            }

        case .int:
            if Int(value.rawValue) == nil {
                return ValidationError(
                    parameter: parameter,
                    value: value,
                    message: "Expected integer, got '\(value.rawValue)'"
                )
            }

        case .float:
            if Double(value.rawValue) == nil {
                return ValidationError(
                    parameter: parameter,
                    value: value,
                    message: "Expected number, got '\(value.rawValue)'"
                )
            }

        case .`enum`:
            if let validValues = parameter.validValues {
                let loweredValid = validValues.map { $0.lowercased() }
                if !loweredValid.contains(raw) {
                    return ValidationError(
                        parameter: parameter,
                        value: value,
                        message: "Expected one of [\(validValues.joined(separator: ", "))], got '\(value.rawValue)'"
                    )
                }
            }

        case .string, .path, .color, .list:
            break // No validation for these types
        }

        return nil
    }
}
