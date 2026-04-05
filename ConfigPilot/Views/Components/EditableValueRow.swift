import SwiftUI

struct EditableValueRow: View {
    let value: ConfigValue
    let parameter: Parameter?
    let tool: Tool
    let onSave: (String) -> Void

    @State private var isEditing = false
    @State private var editText = ""

    var body: some View {
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

                    if isEditing {
                        editControl
                    } else {
                        Text(value.rawValue)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .onTapGesture {
                                beginEditing()
                            }

                        Button {
                            beginEditing()
                        } label: {
                            Image(systemName: "pencil")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.tertiary)
                    }
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
            Divider()
            Button("Edit Value...") {
                beginEditing()
            }
        }
    }

    @ViewBuilder
    private var editControl: some View {
        if let parameter = parameter {
            switch parameter.type {
            case .bool:
                boolPicker

            case .`enum`:
                if let validValues = parameter.validValues, !validValues.isEmpty {
                    enumPicker(values: validValues)
                } else {
                    textEditor
                }

            default:
                textEditor
            }
        } else {
            textEditor
        }
    }

    private var boolPicker: some View {
        HStack(spacing: 4) {
            Picker("", selection: $editText) {
                Text("true").tag("true")
                Text("false").tag("false")
            }
            .pickerStyle(.segmented)
            .frame(width: 130)
            .onChange(of: editText) { _, newValue in
                onSave(newValue)
                isEditing = false
            }

            cancelButton
        }
    }

    private func enumPicker(values: [String]) -> some View {
        HStack(spacing: 4) {
            Picker("", selection: $editText) {
                ForEach(values, id: \.self) { val in
                    Text(val).tag(val)
                }
            }
            .frame(width: 140)
            .onChange(of: editText) { _, newValue in
                onSave(newValue)
                isEditing = false
            }

            cancelButton
        }
    }

    private var textEditor: some View {
        HStack(spacing: 4) {
            TextField("Value", text: $editText)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: 200)
                .onSubmit {
                    onSave(editText)
                    isEditing = false
                }

            Button {
                onSave(editText)
                isEditing = false
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)

            cancelButton
        }
    }

    private var cancelButton: some View {
        Button {
            isEditing = false
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    private func beginEditing() {
        editText = value.rawValue
        isEditing = true
    }
}
