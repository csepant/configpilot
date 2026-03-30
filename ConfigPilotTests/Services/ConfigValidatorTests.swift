import XCTest
@testable import ConfigPilot

final class ConfigValidatorTests: XCTestCase {
    let validator = ConfigValidator()

    private let testTool = Tool(
        id: "git", name: "Git", category: .cli,
        configPaths: ["~/.gitconfig"], configFormat: .ini,
        schemaRef: "git.json", iconName: "arrow.triangle.branch"
    )

    private var testSchema: [ParameterSection] {
        [
            ParameterSection(id: "core", name: "Core", description: nil, parameters: [
                Parameter(id: "core.autocrlf", key: "autocrlf", type: .enum,
                         defaultValue: "false", description: "Line ending conversion",
                         validValues: ["true", "false", "input"]),
                Parameter(id: "core.editor", key: "editor", type: .string,
                         description: "Commit editor"),
                Parameter(id: "core.compression", key: "compression", type: .int,
                         defaultValue: "9", description: "Compression level"),
                Parameter(id: "core.bigFileThreshold", key: "bigFileThreshold", type: .int,
                         defaultValue: "512m", description: "Big file threshold"),
            ]),
            ParameterSection(id: "push", name: "Push", description: nil, parameters: [
                Parameter(id: "push.default", key: "default", type: .enum,
                         defaultValue: "simple", description: "Push default",
                         validValues: ["nothing", "current", "upstream", "simple", "matching"]),
                Parameter(id: "push.autoSetupRemote", key: "autoSetupRemote", type: .bool,
                         defaultValue: "false", description: "Auto setup remote"),
            ]),
        ]
    }

    // MARK: - Set vs Unset Detection

    func testIdentifiesSetValues() {
        let values = [
            ConfigValue(key: "core.autocrlf", rawValue: "input", sourceFile: "~/.gitconfig", lineNumber: 1),
            ConfigValue(key: "core.editor", rawValue: "vim", sourceFile: "~/.gitconfig", lineNumber: 2),
        ]

        let state = validator.validate(values: values, schema: testSchema, tool: testTool)

        XCTAssertEqual(state.setValues.count, 2)
        XCTAssertEqual(state.unsetParameters.count, 4) // compression, bigFileThreshold, push.default, push.autoSetupRemote
    }

    func testIdentifiesUnsetParameters() {
        let values: [ConfigValue] = []

        let state = validator.validate(values: values, schema: testSchema, tool: testTool)

        XCTAssertEqual(state.setValues.count, 0)
        XCTAssertEqual(state.unsetParameters.count, 6) // all parameters
    }

    // MARK: - Type Validation

    func testValidEnumValue() {
        let values = [
            ConfigValue(key: "core.autocrlf", rawValue: "input", sourceFile: "~/.gitconfig", lineNumber: 1),
        ]

        let state = validator.validate(values: values, schema: testSchema, tool: testTool)

        let autocrlfErrors = state.validationErrors.filter { $0.parameter.id == "core.autocrlf" }
        XCTAssertTrue(autocrlfErrors.isEmpty, "Valid enum value should not produce error")
    }

    func testInvalidEnumValue() {
        let values = [
            ConfigValue(key: "core.autocrlf", rawValue: "banana", sourceFile: "~/.gitconfig", lineNumber: 1),
        ]

        let state = validator.validate(values: values, schema: testSchema, tool: testTool)

        let autocrlfErrors = state.validationErrors.filter { $0.parameter.id == "core.autocrlf" }
        XCTAssertEqual(autocrlfErrors.count, 1)
        XCTAssertTrue(autocrlfErrors[0].message.contains("banana"))
    }

    func testValidBoolValue() {
        let values = [
            ConfigValue(key: "push.autoSetupRemote", rawValue: "true", sourceFile: "~/.gitconfig", lineNumber: 1),
        ]

        let state = validator.validate(values: values, schema: testSchema, tool: testTool)

        let boolErrors = state.validationErrors.filter { $0.parameter.id == "push.autoSetupRemote" }
        XCTAssertTrue(boolErrors.isEmpty)
    }

    func testInvalidBoolValue() {
        let values = [
            ConfigValue(key: "push.autoSetupRemote", rawValue: "banana", sourceFile: "~/.gitconfig", lineNumber: 1),
        ]

        let state = validator.validate(values: values, schema: testSchema, tool: testTool)

        let boolErrors = state.validationErrors.filter { $0.parameter.id == "push.autoSetupRemote" }
        XCTAssertEqual(boolErrors.count, 1)
        XCTAssertTrue(boolErrors[0].message.contains("Expected bool"))
    }

    func testInvalidIntValue() {
        let values = [
            ConfigValue(key: "core.compression", rawValue: "banana", sourceFile: "~/.gitconfig", lineNumber: 1),
        ]

        let state = validator.validate(values: values, schema: testSchema, tool: testTool)

        let intErrors = state.validationErrors.filter { $0.parameter.id == "core.compression" }
        XCTAssertEqual(intErrors.count, 1)
        XCTAssertTrue(intErrors[0].message.contains("Expected integer"))
    }

    // MARK: - Override Detection

    func testDetectsOverrides() {
        let values = [
            ConfigValue(key: "core.autocrlf", rawValue: "true", sourceFile: "~/.gitconfig", lineNumber: 1),
            ConfigValue(key: "core.autocrlf", rawValue: "input", sourceFile: "~/.config/git/config", lineNumber: 5),
        ]

        let state = validator.validate(values: values, schema: testSchema, tool: testTool)

        XCTAssertEqual(state.overrides.count, 1)
        XCTAssertEqual(state.overrides[0].parameter.id, "core.autocrlf")
        XCTAssertEqual(state.overrides[0].values.count, 2)
    }

    // MARK: - Deprecated Detection

    func testFlagsDeprecatedParameters() {
        let deprecatedSchema = [
            ParameterSection(id: "core", name: "Core", description: nil, parameters: [
                Parameter(id: "core.legacyHeaders", key: "legacyHeaders", type: .bool,
                         description: "Legacy header format", deprecated: true,
                         deprecatedMessage: "Use core.newHeaders instead"),
            ])
        ]

        let values = [
            ConfigValue(key: "core.legacyHeaders", rawValue: "true", sourceFile: "~/.gitconfig", lineNumber: 1),
        ]

        let state = validator.validate(values: values, schema: deprecatedSchema, tool: testTool)

        XCTAssertEqual(state.validationErrors.count, 1)
        XCTAssertTrue(state.validationErrors[0].message.contains("core.newHeaders"))
    }

    // MARK: - Unknown Parameters

    func testUnknownParametersAreIncludedInSetValues() {
        let values = [
            ConfigValue(key: "custom.myKey", rawValue: "myValue", sourceFile: "~/.gitconfig", lineNumber: 1),
        ]

        let state = validator.validate(values: values, schema: testSchema, tool: testTool)

        XCTAssertEqual(state.setValues.count, 1)
        // No validation error for unknown keys
        XCTAssertTrue(state.validationErrors.isEmpty)
    }
}
