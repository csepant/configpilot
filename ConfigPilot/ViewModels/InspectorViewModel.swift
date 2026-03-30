import SwiftUI

@MainActor
class InspectorViewModel: ObservableObject {
    @Published var configState: ConfigState?
    @Published var configFileURLs: [URL] = []

    private let scanner = ConfigScanner()
    private let parser = ConfigParser()
    private let validator = ConfigValidator()
    private let schemaStore = SchemaStore()
    private let watcher = FSEventWatcher()

    func load(tool: Tool) {
        schemaStore.loadCatalog()
        scan(tool: tool)

        // Set up file watching
        let files = scanner.scan(tool: tool)
        watcher.watch(paths: files) { [weak self] _ in
            Task { @MainActor in
                self?.scan(tool: tool)
            }
        }
    }

    private func scan(tool: Tool) {
        let files = scanner.scan(tool: tool)
        configFileURLs = files

        var allValues: [ConfigValue] = []
        for file in files {
            if let values = try? parser.parse(file: file, format: tool.configFormat) {
                allValues.append(contentsOf: values)
            }
        }

        guard let sections = schemaStore.schema(for: tool.id) else {
            configState = ConfigState(
                tool: tool,
                setValues: allValues,
                unsetParameters: [],
                validationErrors: [],
                overrides: []
            )
            return
        }

        configState = validator.validate(values: allValues, schema: sections, tool: tool)
    }

    deinit {
        watcher.stopAll()
    }
}
