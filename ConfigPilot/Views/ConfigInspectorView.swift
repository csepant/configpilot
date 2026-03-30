import SwiftUI

struct ConfigInspectorView: View {
    let tool: Tool
    @StateObject private var viewModel = InspectorViewModel()
    @State private var filterMode: InspectorFilter = .set

    enum InspectorFilter: String, CaseIterable {
        case set = "Set"
        case defaults = "Defaults"
        case issues = "Issues"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Summary bar
            if let state = viewModel.configState {
                HStack(spacing: 16) {
                    summaryPill(
                        count: state.setValues.count,
                        label: "set",
                        color: .green
                    )
                    summaryPill(
                        count: state.unsetParameters.count,
                        label: "using defaults",
                        color: .secondary
                    )
                    summaryPill(
                        count: state.validationErrors.count,
                        label: state.validationErrors.count == 1 ? "issue" : "issues",
                        color: state.validationErrors.isEmpty ? .secondary : .orange
                    )
                    Spacer()

                    if let fileURL = viewModel.configFileURLs.first {
                        Button {
                            NSWorkspace.shared.open(fileURL)
                        } label: {
                            Label("Open in Editor", systemImage: "pencil.and.outline")
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

                // Filter
                Picker("", selection: $filterMode) {
                    ForEach(InspectorFilter.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                // Content
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
                            ContentUnavailableView(
                                "All Parameters Set",
                                systemImage: "checkmark.circle",
                                description: Text("Every known parameter has an explicit value.")
                            )
                            Spacer()
                        }
                    } else {
                        defaultsList(state: state)
                    }

                case .issues:
                    if state.validationErrors.isEmpty {
                        VStack {
                            ContentUnavailableView(
                                "No Issues Found",
                                systemImage: "checkmark.circle",
                                description: Text("All configured values are valid.")
                            )
                            Spacer()
                        }
                    } else {
                        issuesList(state: state)
                    }
                }
            } else {
                VStack {
                    ContentUnavailableView(
                        "Scanning...",
                        systemImage: "magnifyingglass",
                        description: Text("Looking for configuration files...")
                    )
                    Spacer()
                }
            }
        }
        .onAppear {
            viewModel.load(tool: tool)
        }
        .onChange(of: tool) { _, newTool in
            viewModel.load(tool: newTool)
        }
    }

    private func summaryPill(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .fontWeight(.semibold)
            Text(label)
        }
        .font(.caption)
        .foregroundStyle(color)
    }

    private func setValuesList(state: ConfigState) -> some View {
        List {
            ForEach(state.setValues) { value in
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(value.key)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.medium)
                                .textSelection(.enabled)

                            Spacer()

                            Text(value.rawValue)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }

                        if let line = value.lineNumber {
                            Text("Source: \(value.sourceFile) (line \(line))")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .contextMenu {
                    Button("Copy Key") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(value.key, forType: .string)
                    }
                    Button("Copy Value") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(value.rawValue, forType: .string)
                    }
                    Button("Copy as Config Line") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("\(value.key) = \(value.rawValue)", forType: .string)
                    }
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
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
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
