import SwiftUI

struct ConfigInspectorView: View {
    let tool: Tool
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: InspectorViewModel
    @State private var filterMode: InspectorFilter = .set
    @State private var addingParameter: Parameter?
    @State private var addValue = ""

    init(tool: Tool, schemaStore: SchemaStore) {
        self.tool = tool
        _viewModel = StateObject(wrappedValue: InspectorViewModel(schemaStore: schemaStore))
    }

    enum InspectorFilter: String, CaseIterable {
        case set = "Set"
        case defaults = "Defaults"
        case issues = "Issues"
    }

    var body: some View {
        VStack(spacing: 0) {
            if let state = viewModel.configState {
                // Summary bar
                HStack(spacing: 16) {
                    summaryPill(count: state.setValues.count, label: "set", color: .green)
                    summaryPill(count: state.unsetParameters.count, label: "using defaults", color: .secondary)
                    summaryPill(
                        count: state.validationErrors.count,
                        label: state.validationErrors.count == 1 ? "issue" : "issues",
                        color: state.validationErrors.isEmpty ? .secondary : .orange
                    )
                    Spacer()

                    if let fileURL = viewModel.configFileURLs.first {
                        Button {
                            let folderURL = fileURL.deletingLastPathComponent()
                            NSWorkspace.shared.openTerminal(at: folderURL)
                        } label: {
                            Label("Terminal", systemImage: "terminal")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Open terminal at \(fileURL.deletingLastPathComponent().path)")

                        Button {
                            NSWorkspace.shared.open(fileURL)
                        } label: {
                            Label("Editor", systemImage: "pencil.and.outline")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help(fileURL.path)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                // Error banner
                if let error = viewModel.editError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.caption)
                        Spacer()
                        Button("Dismiss") { viewModel.editError = nil }
                            .font(.caption)
                            .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.1))
                }

                Picker("", selection: $filterMode) {
                    ForEach(InspectorFilter.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                switch filterMode {
                case .set:
                    if state.setValues.isEmpty {
                        VStack {
                            ContentUnavailableView(
                                "No Configuration Found",
                                systemImage: "doc.text",
                                description: Text("No configuration file detected for \(tool.name). Config is typically stored at \(tool.configPaths.joined(separator: " or ")).")
                            )
                            Spacer()
                        }
                    } else {
                        setValuesList(state: state)
                    }

                case .defaults:
                    if state.unsetParameters.isEmpty {
                        VStack {
                            ContentUnavailableView("All Parameters Set", systemImage: "checkmark.circle",
                                description: Text("Every known parameter has an explicit value."))
                            Spacer()
                        }
                    } else {
                        defaultsList(state: state)
                    }

                case .issues:
                    if state.validationErrors.isEmpty {
                        VStack {
                            ContentUnavailableView("No Issues Found", systemImage: "checkmark.circle",
                                description: Text("All configured values are valid."))
                            Spacer()
                        }
                    } else {
                        issuesList(state: state)
                    }
                }
            } else {
                VStack {
                    ContentUnavailableView("Scanning...", systemImage: "magnifyingglass",
                        description: Text("Looking for configuration files..."))
                    Spacer()
                }
            }
        }
        .onAppear { viewModel.load(tool: tool) }
        .onChange(of: tool) { _, newTool in viewModel.load(tool: newTool) }
        .onChange(of: appState.parameterToAdd) { _, param in
            if let param = param {
                addingParameter = param
                appState.parameterToAdd = nil
            }
        }
        .sheet(item: $addingParameter) { param in
            AddParameterSheet(parameter: param, tool: tool) { value in
                viewModel.addParameter(param, value: value, tool: tool)
            }
        }
    }

    private func summaryPill(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text("\(count)").fontWeight(.semibold)
            Text(label)
        }
        .font(.caption)
        .foregroundStyle(color)
    }

    /// Look up the schema Parameter matching a ConfigValue key
    private func parameterForValue(_ value: ConfigValue) -> Parameter? {
        guard let sections = appState.schemaStore.schema(for: tool.id) else { return nil }
        return sections.flatMap(\.parameters).first { $0.id == value.key }
    }

    private func setValuesList(state: ConfigState) -> some View {
        List {
            ForEach(state.setValues) { value in
                EditableValueRow(
                    value: value,
                    parameter: parameterForValue(value),
                    tool: tool
                ) { newValue in
                    viewModel.updateValue(value, newValue: newValue, tool: tool)
                }
            }
        }
        .listStyle(.inset)
    }

    private func defaultsList(state: ConfigState) -> some View {
        List {
            ForEach(state.unsetParameters) { param in
                HStack {
                    Circle()
                        .fill(.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(param.id)
                                .font(.system(.body, design: .monospaced))

                            Spacer()

                            if let defaultValue = param.defaultValue {
                                Text(defaultValue)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }

                            Button {
                                addingParameter = param
                                addValue = param.defaultValue ?? ""
                            } label: {
                                Label("Add", systemImage: "plus.circle")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }

                        Text(param.description)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .listStyle(.inset)
    }

    private func issuesList(state: ConfigState) -> some View {
        List {
            ForEach(state.validationErrors) { error in
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(error.parameter.id)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.medium)
                            Spacer()
                            Text(error.value.rawValue)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.red)
                        }
                        Text(error.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let line = error.value.lineNumber {
                            Text("Source: \(error.value.sourceFile) (line \(line))")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
    }
}

// MARK: - Add Parameter Sheet

struct AddParameterSheet: View {
    let parameter: Parameter
    let tool: Tool
    let onAdd: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var value: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Parameter")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text(parameter.id)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                Text(parameter.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Value")
                    .font(.subheadline)
                    .fontWeight(.medium)

                switch parameter.type {
                case .bool:
                    Picker("", selection: $value) {
                        Text("true").tag("true")
                        Text("false").tag("false")
                    }
                    .pickerStyle(.segmented)

                case .`enum`:
                    if let validValues = parameter.validValues, !validValues.isEmpty {
                        Picker("", selection: $value) {
                            Text("Select...").tag("")
                            ForEach(validValues, id: \.self) { val in
                                Text(val).tag(val)
                            }
                        }
                    } else {
                        TextField("Enter value", text: $value)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }

                default:
                    TextField("Enter value", text: $value)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }

                if let defaultValue = parameter.defaultValue {
                    Text("Default: \(defaultValue)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add to Config") {
                    onAdd(value)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(value.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            value = parameter.defaultValue ?? ""
        }
    }
}
