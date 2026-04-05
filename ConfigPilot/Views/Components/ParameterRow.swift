import SwiftUI

struct ParameterRow: View {
    let parameter: Parameter
    var configValue: ConfigValue?
    var onAddToConfig: ((Parameter) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(parameter.id)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                    .strikethrough(parameter.deprecated)
                    .opacity(parameter.deprecated ? 0.5 : 1)
                    .textSelection(.enabled)

                if let configValue = configValue {
                    ConfigValueBadge(value: configValue.rawValue, style: .set)
                } else if let onAdd = onAddToConfig, !parameter.deprecated {
                    Button {
                        onAdd(parameter)
                    } label: {
                       Image(systemName: "plus.circle")
                            .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }

                Spacer()

                typeBadge
            }

            Text(parameter.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack(spacing: 12) {
                if let defaultValue = parameter.defaultValue {
                    HStack(spacing: 4) {
                        Text("Default:")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(defaultValue)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

                if let validValues = parameter.validValues, !validValues.isEmpty {
                    HStack(spacing: 4) {
                        Text("Valid:")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(validValues.joined(separator: ", "))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

                if let since = parameter.since {
                    HStack(spacing: 4) {
                        Text("Since:")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(since)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if parameter.deprecated, let msg = parameter.deprecatedMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(msg)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Copy Key") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(parameter.id, forType: .string)
            }
            if let defaultValue = parameter.defaultValue {
                Button("Copy Default Value") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(defaultValue, forType: .string)
                }
            }
            Button("Copy as Config Line") {
                let value = configValue?.rawValue ?? parameter.defaultValue ?? ""
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("\(parameter.id) = \(value)", forType: .string)
            }
        }
    }

    private var typeBadge: some View {
        Text(parameter.type.rawValue)
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(typeColor.opacity(0.12))
            .foregroundStyle(typeColor)
            .clipShape(Capsule())
    }

    private var typeColor: Color {
        switch parameter.type {
        case .bool: return .blue
        case .string: return .green
        case .int, .float: return .purple
        case .`enum`: return .orange
        case .path: return .cyan
        case .color: return .pink
        case .list: return .indigo
        }
    }
}

#Preview("Parameter - Enum with value set") {
    ParameterRow(
        parameter: Parameter(
            id: "core.autocrlf", key: "autocrlf", type: .enum,
            defaultValue: "false",
            description: "Controls automatic line ending conversion. Set to 'input' on macOS/Linux to convert CRLF to LF on commit while leaving the working directory unchanged.",
            validValues: ["true", "false", "input"],
            since: "1.5.0"
        ),
        configValue: ConfigValue(key: "core.autocrlf", rawValue: "input", sourceFile: "~/.gitconfig", lineNumber: 4)
    )
    .padding()
    .frame(width: 500)
}

#Preview("Parameter - String unset") {
    ParameterRow(
        parameter: Parameter(
            id: "core.editor", key: "editor", type: .string,
            description: "The editor used for commit messages and interactive rebase. Falls back to $VISUAL or $EDITOR environment variables if not set."
        )
    )
    .padding()
    .frame(width: 500)
}

#Preview("Parameter - Deprecated") {
    ParameterRow(
        parameter: Parameter(
            id: "core.legacyHeaders", key: "legacyHeaders", type: .bool,
            defaultValue: "true",
            description: "Use legacy header format for pack files.",
            deprecated: true, deprecatedMessage: "Use core.newHeaders instead"
        )
    )
    .padding()
    .frame(width: 500)
}
