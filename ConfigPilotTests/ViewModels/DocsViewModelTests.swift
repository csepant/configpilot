import XCTest
@testable import ConfigPilot

@MainActor
final class DocsViewModelTests: XCTestCase {
    func testSectionExpandCollapse() {
        let viewModel = DocsViewModel()
        viewModel.sections = [
            ParameterSection(id: "core", name: "Core", description: nil, parameters: [
                Parameter(id: "core.editor", key: "editor", type: .string, description: "Editor")
            ]),
            ParameterSection(id: "push", name: "Push", description: nil, parameters: [
                Parameter(id: "push.default", key: "default", type: .enum, description: "Push default")
            ])
        ]
        viewModel.expandedSections = Set(viewModel.sections.map(\.id))

        XCTAssertTrue(viewModel.isSectionExpanded("core"))
        XCTAssertTrue(viewModel.isSectionExpanded("push"))

        viewModel.toggleSection("core")
        XCTAssertFalse(viewModel.isSectionExpanded("core"))
        XCTAssertTrue(viewModel.isSectionExpanded("push"))

        viewModel.toggleSection("core")
        XCTAssertTrue(viewModel.isSectionExpanded("core"))
    }

    func testSearchFiltersParameters() {
        let viewModel = DocsViewModel()
        viewModel.sections = [
            ParameterSection(id: "core", name: "Core", description: nil, parameters: [
                Parameter(id: "core.editor", key: "editor", type: .string, description: "The editor used for commit messages"),
                Parameter(id: "core.autocrlf", key: "autocrlf", type: .enum, description: "Line ending conversion"),
            ]),
            ParameterSection(id: "push", name: "Push", description: nil, parameters: [
                Parameter(id: "push.default", key: "default", type: .enum, description: "Push default behavior"),
            ])
        ]
        viewModel.expandedSections = Set(viewModel.sections.map(\.id))

        let results = viewModel.filteredSections(query: "editor", deprecated: false)
        let allParams = results.flatMap(\.parameters)
        XCTAssertEqual(allParams.count, 1)
        XCTAssertEqual(allParams[0].id, "core.editor")
    }

    func testSearchByDescription() {
        let viewModel = DocsViewModel()
        viewModel.sections = [
            ParameterSection(id: "core", name: "Core", description: nil, parameters: [
                Parameter(id: "core.editor", key: "editor", type: .string, description: "The editor used for commit messages"),
                Parameter(id: "core.pager", key: "pager", type: .string, description: "The pager for output"),
            ])
        ]
        viewModel.expandedSections = Set(viewModel.sections.map(\.id))

        let results = viewModel.filteredSections(query: "commit", deprecated: false)
        let allParams = results.flatMap(\.parameters)
        XCTAssertEqual(allParams.count, 1)
        XCTAssertEqual(allParams[0].id, "core.editor")
    }

    func testDeprecatedFilter() {
        let viewModel = DocsViewModel()
        viewModel.sections = [
            ParameterSection(id: "core", name: "Core", description: nil, parameters: [
                Parameter(id: "core.editor", key: "editor", type: .string, description: "Editor"),
                Parameter(id: "core.legacy", key: "legacy", type: .bool, description: "Legacy option", deprecated: true, deprecatedMessage: "Use something else"),
            ])
        ]
        viewModel.expandedSections = Set(viewModel.sections.map(\.id))

        let results = viewModel.filteredSections(query: "", deprecated: true)
        let allParams = results.flatMap(\.parameters)
        XCTAssertEqual(allParams.count, 1)
        XCTAssertEqual(allParams[0].id, "core.legacy")
    }

    func testConfigValueLookup() {
        let viewModel = DocsViewModel()
        viewModel.configValues = [
            "core.editor": ConfigValue(key: "core.editor", rawValue: "vim", sourceFile: "~/.gitconfig", lineNumber: 1)
        ]

        XCTAssertNotNil(viewModel.configValue(for: "core.editor"))
        XCTAssertEqual(viewModel.configValue(for: "core.editor")?.rawValue, "vim")
        XCTAssertNil(viewModel.configValue(for: "core.pager"))
    }
}
