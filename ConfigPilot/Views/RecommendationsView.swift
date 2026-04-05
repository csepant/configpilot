import SwiftUI

struct RecommendationsView: View {
    let tool: Tool
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: RecommendationsViewModel

    init(tool: Tool, schemaStore: SchemaStore) {
        self.tool = tool
        _viewModel = StateObject(wrappedValue: RecommendationsViewModel(schemaStore: schemaStore))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("AI Recommendations")
                    .font(.headline)
                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button {
                        Task {
                            await viewModel.getRecommendations(for: tool)
                        }
                    } label: {
                        Label("Analyze", systemImage: "sparkles")
                    }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                }
            }
            .padding()

            Divider()

            if let error = viewModel.error {
                VStack {
                    ContentUnavailableView(
                        "Error",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                    Spacer()
                }
            } else if viewModel.recommendations.isEmpty && !viewModel.isLoading {
                VStack {
                    ContentUnavailableView(
                        "No Recommendations",
                        systemImage: "sparkles",
                        description: Text("Click 'Analyze' to get AI-powered suggestions for your \(tool.name) configuration.")
                    )
                    Spacer()
                }
            } else {
                List {
                    ForEach(viewModel.recommendations) { rec in
                        RecommendationCard(recommendation: rec) {
                            viewModel.dismiss(rec)
                        } onCopy: {
                            viewModel.copyToClipboard(rec)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 280)
    }
}

struct RecommendationCard: View {
    let recommendation: Recommendation
    let onDismiss: () -> Void
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recommendation.parameterId)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)

                Spacer()

                impactBadge(recommendation.impact)
            }

            HStack {
                Text("Suggested:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(recommendation.suggestedValue)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
            }

            Text(recommendation.rationale)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(4)

            HStack {
                Button("Dismiss", action: onDismiss)
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    onCopy()
                } label: {
                    Label("Copy to config", systemImage: "doc.on.clipboard")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }

    private func impactBadge(_ impact: Recommendation.Impact) -> some View {
        Text(impact.rawValue.uppercased())
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(impactColor(impact).opacity(0.15))
            .foregroundStyle(impactColor(impact))
            .clipShape(Capsule())
    }

    private func impactColor(_ impact: Recommendation.Impact) -> Color {
        switch impact {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

#Preview("Recommendation Card") {
    RecommendationCard(
        recommendation: Recommendation(
            id: UUID(),
            parameterId: "core.fsmonitor",
            suggestedValue: "true",
            rationale: "Enables the built-in file system monitor, which significantly speeds up git status and other commands in large repositories.",
            impact: .high
        ),
        onDismiss: {},
        onCopy: {}
    )
    .padding()
    .frame(width: 320)
}
