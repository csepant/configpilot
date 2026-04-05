import SwiftUI

@MainActor
class RecommendationsViewModel: ObservableObject {
    @Published var recommendations: [Recommendation] = []
    @Published var isLoading = false
    @Published var error: String?

    private let schemaStore: SchemaStore
    private let scanner = ConfigScanner()
    private let parser = ConfigParser()
    private let validator = ConfigValidator()
    private let promptBuilder = PromptBuilder()
    private var lastRequestTime: Date?
    private let cooldownInterval: TimeInterval = 30

    init(schemaStore: SchemaStore) {
        self.schemaStore = schemaStore
    }

    func getRecommendations(for tool: Tool) async {
        if let lastTime = lastRequestTime,
           Date().timeIntervalSince(lastTime) < cooldownInterval {
            error = "Please wait before requesting again."
            return
        }

        guard let apiKey = KeychainHelper.load(), !apiKey.isEmpty else {
            error = "No API key configured. Add your Claude API key in Settings (Cmd+,)."
            return
        }

        isLoading = true
        error = nil

        do {
            let files = scanner.scan(tool: tool)
            var allValues: [ConfigValue] = []
            for file in files {
                if let values = try? parser.parse(file: file, format: tool.configFormat) {
                    allValues.append(contentsOf: values)
                }
            }

            let sections = schemaStore.schema(for: tool.id) ?? []
            let configState = validator.validate(values: allValues, schema: sections, tool: tool)

            let prompt = promptBuilder.buildPrompt(configState: configState, schema: sections)
            let client = ClaudeAPIClient(apiKey: apiKey)
            let recs = try await client.getRecommendations(prompt: prompt)

            recommendations = recs
            lastRequestTime = Date()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func dismiss(_ recommendation: Recommendation) {
        recommendations.removeAll { $0.id == recommendation.id }
    }

    func copyToClipboard(_ recommendation: Recommendation) {
        let line = "\(recommendation.parameterId) = \(recommendation.suggestedValue)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(line, forType: .string)
    }
}
