import SwiftUI

struct SidebarView: View {
    @Binding var selectedTool: Tool?
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = CatalogViewModel()
    @State private var searchText = ""

    var body: some View {
        List(selection: $selectedTool) {
            ForEach(ToolCategory.allCases, id: \.self) { category in
                let tools = viewModel.filteredTools(query: searchText)
                    .filter { $0.category == category }

                if !tools.isEmpty {
                    Section(category.rawValue) {
                        ForEach(tools) { tool in
                            toolRow(tool)
                                .tag(tool)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Filter tools")
        .navigationTitle("ConfigPilot")
        .onAppear {
            viewModel.load(schemaStore: appState.schemaStore, scanner: appState.configScanner)
        }
    }

    private func toolRow(_ tool: Tool) -> some View {
        HStack {
            Image(systemName: tool.iconName)
                .frame(width: 20)
                .foregroundStyle(.secondary)

            Text(tool.name)

            Spacer()

            if let count = viewModel.configFileCounts[tool.id], count > 0 {
                Text("\(count)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.tertiary)
                    .clipShape(Capsule())
            }
        }
    }
}
