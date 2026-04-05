import SwiftUI

struct DocsBrowserView: View {
    let tool: Tool
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = DocsViewModel()
    @State private var searchText = ""
    @State private var filterMode: FilterMode = .all

    enum FilterMode: String, CaseIterable {
        case all = "All"
        case deprecated = "Deprecated"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search and filter bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search parameters...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Picker("", selection: $filterMode) {
                    ForEach(FilterMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Parameter list
            let sections = viewModel.filteredSections(query: searchText, deprecated: filterMode == .deprecated)

            if sections.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    ForEach(sections) { section in
                        Section {
                            if viewModel.isSectionExpanded(section.id) {
                                ForEach(section.parameters) { param in
                                    ParameterRow(
                                        parameter: param,
                                        configValue: viewModel.configValue(for: param.id),
                                        onAddToConfig: { parameter in
                                            appState.parameterToAdd = parameter
                                        }
                                    )
                                }
                            }
                        } header: {
                            SectionHeader(
                                title: section.name,
                                description: section.description,
                                count: section.parameters.count,
                                isExpanded: viewModel.isSectionExpanded(section.id)
                            ) {
                                viewModel.toggleSection(section.id)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .onAppear {
            viewModel.load(tool: tool, schemaStore: appState.schemaStore, scanner: appState.configScanner)
        }
        .onChange(of: tool) { _, newTool in
            viewModel.load(tool: newTool, schemaStore: appState.schemaStore, scanner: appState.configScanner)
        }
    }
}
