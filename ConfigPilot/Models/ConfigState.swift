import Foundation

struct ConfigState {
    let tool: Tool
    let setValues: [ConfigValue]
    let unsetParameters: [Parameter]
    let validationErrors: [ValidationError]
    let overrides: [ConfigOverride]
}

struct ValidationError: Identifiable {
    let id = UUID()
    let parameter: Parameter
    let value: ConfigValue
    let message: String
}

struct ConfigOverride: Identifiable {
    let id = UUID()
    let parameter: Parameter
    let values: [ConfigValue]
}
