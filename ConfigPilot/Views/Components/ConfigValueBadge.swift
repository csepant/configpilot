import SwiftUI

struct ConfigValueBadge: View {
    let value: String
    let style: BadgeStyle

    enum BadgeStyle {
        case set
        case `default`
        case invalid
    }

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)

            Text(value)
                .font(.system(.caption2, design: .monospaced))
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(backgroundColor)
        .clipShape(Capsule())
    }

    private var dotColor: Color {
        switch style {
        case .set: return .green
        case .default: return .secondary
        case .invalid: return .orange
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .set: return .green.opacity(0.1)
        case .default: return .secondary.opacity(0.1)
        case .invalid: return .orange.opacity(0.1)
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        ConfigValueBadge(value: "input", style: .set)
        ConfigValueBadge(value: "9", style: .default)
        ConfigValueBadge(value: "banana", style: .invalid)
    }
    .padding()
}
