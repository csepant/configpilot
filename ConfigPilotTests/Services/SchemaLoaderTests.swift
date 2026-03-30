import XCTest
@testable import ConfigPilot

final class SchemaLoaderTests: XCTestCase {
    // MARK: - Schema Deserialization

    func testDeserializeSchemaFromJSON() throws {
        let jsonURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Fixtures/schemas/git-test.json")

        let data = try Data(contentsOf: jsonURL)
        let decoder = JSONDecoder()
        let schema = try decoder.decode(SchemaLoader.SchemaFile.self, from: data)

        XCTAssertEqual(schema.tool.id, "git")
        XCTAssertEqual(schema.tool.name, "Git")
        XCTAssertEqual(schema.tool.category, "CLI Tools")
        XCTAssertEqual(schema.tool.configPaths, ["~/.gitconfig"])
        XCTAssertEqual(schema.tool.configFormat, "ini")
        XCTAssertEqual(schema.tool.iconName, "arrow.triangle.branch")

        XCTAssertEqual(schema.sections.count, 3)

        // Core section
        let coreSection = schema.sections[0]
        XCTAssertEqual(coreSection.id, "core")
        XCTAssertEqual(coreSection.name, "Core Settings")
        XCTAssertEqual(coreSection.parameters.count, 3)

        // Check autocrlf parameter
        let autocrlf = coreSection.parameters[0]
        XCTAssertEqual(autocrlf.id, "core.autocrlf")
        XCTAssertEqual(autocrlf.key, "autocrlf")
        XCTAssertEqual(autocrlf.type, .enum)
        XCTAssertEqual(autocrlf.defaultValue, "false")
        XCTAssertEqual(autocrlf.validValues, ["true", "false", "input"])
        XCTAssertEqual(autocrlf.since, "1.5.0")
        XCTAssertFalse(autocrlf.deprecated)
    }

    func testDeserializeParameterTypes() throws {
        let jsonURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Fixtures/schemas/git-test.json")

        let data = try Data(contentsOf: jsonURL)
        let schema = try JSONDecoder().decode(SchemaLoader.SchemaFile.self, from: data)

        let allParams = schema.sections.flatMap(\.parameters)

        // Check we have different types
        let types = Set(allParams.map(\.type))
        XCTAssertTrue(types.contains(.enum))
        XCTAssertTrue(types.contains(.string))
        XCTAssertTrue(types.contains(.bool))
    }

    func testDeserializeNullableFields() throws {
        let jsonURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Fixtures/schemas/git-test.json")

        let data = try Data(contentsOf: jsonURL)
        let schema = try JSONDecoder().decode(SchemaLoader.SchemaFile.self, from: data)

        // core.editor has null defaultValue, null validValues, null since
        let editor = schema.sections[0].parameters[1]
        XCTAssertEqual(editor.id, "core.editor")
        XCTAssertNil(editor.defaultValue)
        XCTAssertNil(editor.validValues)
        XCTAssertNil(editor.since)
    }

    // MARK: - Tool Construction

    func testToolConstruction() throws {
        let jsonURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Fixtures/schemas/git-test.json")

        let data = try Data(contentsOf: jsonURL)
        let schema = try JSONDecoder().decode(SchemaLoader.SchemaFile.self, from: data)

        let tool = Tool(
            id: schema.tool.id,
            name: schema.tool.name,
            category: ToolCategory(rawValue: schema.tool.category) ?? .cli,
            configPaths: schema.tool.configPaths,
            configFormat: ConfigFormat(rawValue: schema.tool.configFormat) ?? .ini,
            schemaRef: "\(schema.tool.id).json",
            iconName: schema.tool.iconName
        )

        XCTAssertEqual(tool.id, "git")
        XCTAssertEqual(tool.name, "Git")
        XCTAssertEqual(tool.category, .cli)
        XCTAssertEqual(tool.configFormat, .ini)
    }
}
