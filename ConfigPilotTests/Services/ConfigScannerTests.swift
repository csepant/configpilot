import XCTest
@testable import ConfigPilot

final class ConfigScannerTests: XCTestCase {
    let scanner = ConfigScanner()

    func testScanExpandsTilde() {
        let tool = Tool(
            id: "test", name: "Test", category: .cli,
            configPaths: ["~/.gitconfig"],
            configFormat: .ini, schemaRef: "test.json", iconName: "gear"
        )

        // This test verifies the scanner doesn't crash and returns URLs
        // The actual result depends on whether ~/.gitconfig exists
        let results = scanner.scan(tool: tool)
        for url in results {
            XCTAssertFalse(url.path.contains("~"), "Tilde should be expanded")
        }
    }

    func testScanReturnsEmptyForNonexistentPaths() {
        let tool = Tool(
            id: "test", name: "Test", category: .cli,
            configPaths: ["~/nonexistent_config_file_12345"],
            configFormat: .ini, schemaRef: "test.json", iconName: "gear"
        )

        let results = scanner.scan(tool: tool)
        XCTAssertTrue(results.isEmpty)
    }

    func testScanFindsExistingFile() throws {
        // Create a temporary config file
        let tmpDir = FileManager.default.temporaryDirectory
        let tmpFile = tmpDir.appendingPathComponent("test-scan-config")
        try "test".write(to: tmpFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        let tool = Tool(
            id: "test", name: "Test", category: .cli,
            configPaths: [tmpFile.path],
            configFormat: .ini, schemaRef: "test.json", iconName: "gear"
        )

        let results = scanner.scan(tool: tool)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].path, tmpFile.path)
    }

    func testScanAllReturnsResultsForMultipleTools() throws {
        let tmpDir = FileManager.default.temporaryDirectory
        let tmpFile1 = tmpDir.appendingPathComponent("test-scan-1")
        let tmpFile2 = tmpDir.appendingPathComponent("test-scan-2")
        try "test1".write(to: tmpFile1, atomically: true, encoding: .utf8)
        try "test2".write(to: tmpFile2, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: tmpFile1)
            try? FileManager.default.removeItem(at: tmpFile2)
        }

        let tools = [
            Tool(id: "tool1", name: "Tool 1", category: .cli,
                 configPaths: [tmpFile1.path], configFormat: .ini,
                 schemaRef: "t1.json", iconName: "gear"),
            Tool(id: "tool2", name: "Tool 2", category: .devTool,
                 configPaths: [tmpFile2.path], configFormat: .toml,
                 schemaRef: "t2.json", iconName: "gear"),
            Tool(id: "tool3", name: "Tool 3", category: .cli,
                 configPaths: ["~/nonexistent_12345"], configFormat: .ini,
                 schemaRef: "t3.json", iconName: "gear"),
        ]

        let results = scanner.scanAll(tools: tools)

        XCTAssertEqual(results.count, 2) // tool3 has no files
        XCTAssertNotNil(results["tool1"])
        XCTAssertNotNil(results["tool2"])
        XCTAssertNil(results["tool3"])
    }
}
