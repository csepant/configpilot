import XCTest
@testable import ConfigPilot

final class InspectorViewModelTests: XCTestCase {
    // These tests verify the validator integration used by InspectorViewModel
    // The actual ViewModel requires MainActor and UI context, so we test the
    // underlying logic directly.

    let validator = ConfigValidator()

    private let testTool = Tool(
        id: "git", name: "Git", category: .cli,
        configPaths: ["~/.gitconfig"], configFormat: .ini,
        schemaRef: "git.json", iconName: "arrow.triangle.branch"
    )

    func testInspectorStateCategories() {
        let schema = [
            ParameterSection(id: "core", name: "Core", description: nil, parameters: [
                Parameter(id: "core.editor", key: "editor", type: .string, description: "Editor"),
                Parameter(id: "core.autocrlf", key: "autocrlf", type: .enum,
                         defaultValue: "false", description: "Line endings",
                         validValues: ["true", "false", "input"]),
                Parameter(id: "core.pager", key: "pager", type: .string, description: "Pager"),
            ])
        ]

        let values = [
            ConfigValue(key: "core.editor", rawValue: "vim", sourceFile: "~/.gitconfig", lineNumber: 1),
            ConfigValue(key: "core.autocrlf", rawValue: "banana", sourceFile: "~/.gitconfig", lineNumber: 2),
        ]

        let state = validator.validate(values: values, schema: schema, tool: testTool)

        // 2 values set
        XCTAssertEqual(state.setValues.count, 2)

        // 1 parameter unset (core.pager)
        XCTAssertEqual(state.unsetParameters.count, 1)
        XCTAssertEqual(state.unsetParameters[0].id, "core.pager")

        // 1 validation error (banana is not a valid enum value)
        XCTAssertEqual(state.validationErrors.count, 1)
        XCTAssertEqual(state.validationErrors[0].parameter.id, "core.autocrlf")
    }

    func testInspectorEmptyConfig() {
        let schema = [
            ParameterSection(id: "core", name: "Core", description: nil, parameters: [
                Parameter(id: "core.editor", key: "editor", type: .string, description: "Editor"),
            ])
        ]

        let state = validator.validate(values: [], schema: schema, tool: testTool)

        XCTAssertTrue(state.setValues.isEmpty)
        XCTAssertEqual(state.unsetParameters.count, 1)
        XCTAssertTrue(state.validationErrors.isEmpty)
    }
}
