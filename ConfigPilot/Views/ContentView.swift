import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showRecommendations = false

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTool: $appState.selectedTool)
                .environmentObject(appState)
        } detail: {
            if let tool = appState.selectedTool {
                HSplitView {
                    DocsBrowserView(tool: tool)
                        .environmentObject(appState)
                        .frame(minWidth: 340, maxWidth: .infinity, maxHeight: .infinity)

                    ConfigInspectorView(tool: tool)
                        .frame(minWidth: 280, maxWidth: .infinity, maxHeight: .infinity)
                }
                .inspector(isPresented: $showRecommendations) {
                    RecommendationsView(tool: tool)
                        .inspectorColumnWidth(min: 280, ideal: 320, max: 400)
                }
            } else {
                ContentUnavailableView(
                    "Select a Tool",
                    systemImage: "wrench.and.screwdriver",
                    description: Text("Choose a tool from the sidebar to explore its configuration.")
                )
            }
        }
        .frame(minWidth: 900, minHeight: 500)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showRecommendations.toggle()
                } label: {
                    Label("AI Recommendations", systemImage: "sparkles")
                }
                .help(showRecommendations ? "Hide AI Recommendations" : "Show AI Recommendations")
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }

            ToolbarItem(placement: .automatic) {
                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
