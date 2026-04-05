import SwiftUI

@MainActor
class InspectorViewModel: ObservableObject {
    @Published var configState: ConfigState?
    @Published var configFileURLs: [URL] = []
    @Published var editError: String?

    private let scanner = ConfigScanner()
    private let parser = ConfigParser()
    private let validator = ConfigValidator()
    private let writer = ConfigWriter()
    private let schemaStore: SchemaStore
    private let watcher = FSEventWatcher()
    private var currentTool: Tool?

    init(schemaStore: SchemaStore) {
        self.schemaStore = schemaStore
    }

    func load(tool: Tool) {
        currentTool = tool
        scan(tool: tool)

        let files = scanner.scan(tool: tool)
        watcher.watch(paths: files) { [weak self] _ in
            Task { @MainActor in
                self?.scan(tool: tool)
            }
        }
    }

    func updateValue(_ configValue: ConfigValue, newValue: String, tool: Tool) {
        guard let lineNumber = configValue.lineNumber else {
            editError = "Cannot edit: no line number available"
            return
        }

        let fileURL = URL(fileURLWithPath: configValue.sourceFile)
        do {
            try writer.updateValue(in: fileURL, at: lineNumber, key: configValue.key, newValue: newValue, format: tool.configFormat)
            editError = nil
            scan(tool: tool)
        } catch {
            editError = error.localizedDescription
        }
    }

    func addParameter(_ parameter: Parameter, value: String, tool: Tool) {
        // Determine target file — use first existing config, or first path
        let targetURL: URL
        if let firstFile = configFileURLs.first {
            targetURL = firstFile
        } else if let firstPath = tool.configPaths.first {
            let expanded = NSString(string: firstPath).expandingTildeInPath
            targetURL = URL(fileURLWithPath: expanded)
        } else {
            editError = "No config file path available"
            return
        }

        // Extract section from parameter id (e.g., "core.editor" → "core")
        let section = parameter.id.contains(".") ? String(parameter.id.prefix(while: { $0 != "." })) : nil

        do {
            if FileManager.default.fileExists(atPath: targetURL.path) {
                try writer.appendValue(to: targetURL, key: parameter.id, value: value, section: section, format: tool.configFormat)
            } else {
                try writer.createFile(at: targetURL, key: parameter.id, value: value, section: section, format: tool.configFormat)
            }
            editError = nil
            scan(tool: tool)
        } catch {
            editError = error.localizedDescription
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
