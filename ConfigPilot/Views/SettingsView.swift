import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var showAPIKey = false
    @State private var saveStatus: String?

    var body: some View {
        TabView {
            apiKeyTab
                .tabItem {
                    Label("API Key", systemImage: "key")
                }

            scanPathsTab
                .tabItem {
                    Label("Scan Paths", systemImage: "folder")
                }
        }
        .frame(width: 500, height: 300)
        .onAppear {
            apiKey = KeychainHelper.load() ?? ""
        }
    }

    private var apiKeyTab: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Claude API Key")
                        .font(.headline)

                    Text("Required for AI-powered configuration recommendations. Your key is stored securely in the macOS Keychain.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        if showAPIKey {
                            TextField("sk-ant-...", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("sk-ant-...", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                        }

                        Button {
                            showAPIKey.toggle()
                        } label: {
                            Image(systemName: showAPIKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.plain)
                    }

                    HStack {
                        Button("Save") {
                            do {
                                try KeychainHelper.save(apiKey: apiKey)
                                saveStatus = "Saved successfully"
                            } catch {
                                saveStatus = "Failed to save: \(error.localizedDescription)"
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Clear") {
                            KeychainHelper.delete()
                            apiKey = ""
                            saveStatus = "API key removed"
                        }
                        .buttonStyle(.bordered)

                        if let status = saveStatus {
                            Text(status)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var scanPathsTab: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Configuration Scan Paths")
                        .font(.headline)

                    Text("ConfigPilot scans these locations for configuration files.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("~/")
                            .font(.system(.body, design: .monospaced))
                        Text("~/.config/")
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding(.vertical, 4)

                    Text("Additional scan path configuration coming in a future update.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
