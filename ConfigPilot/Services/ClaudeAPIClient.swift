import Foundation

class ClaudeAPIClient {
    private let apiKey: String
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-sonnet-4-20250514"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func getRecommendations(prompt: String) async throws -> [Recommendation] {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 2048,
            "system": """
                You are a developer tools expert. Analyze the user's configuration and suggest improvements.
                Return ONLY a JSON array of recommendations. No markdown, no preamble.
                Each recommendation: {"parameterId": "...", "suggestedValue": "...", "rationale": "...", "impact": "low|medium|high"}
                Focus on: security improvements, performance gains, quality-of-life enhancements, and deprecated option replacements.
                Limit to 5-10 most impactful suggestions.
                """,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw APIError.unauthorized
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.httpError(httpResponse.statusCode)
        }

        // Parse the Claude response
        let apiResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let textContent = apiResponse.content.first(where: { $0.type == "text" }) else {
            throw APIError.invalidResponse
        }

        // Try to extract JSON array from the response text
        let text = textContent.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonString: String
        if text.hasPrefix("[") {
            jsonString = text
        } else if let start = text.range(of: "["), let end = text.range(of: "]", options: .backwards) {
            jsonString = String(text[start.lowerBound...end.upperBound])
        } else {
            throw APIError.invalidResponse
        }

        guard let arrayData = jsonString.data(using: .utf8) else {
            throw APIError.invalidResponse
        }

        let rawRecs = try JSONDecoder().decode([RawRecommendation].self, from: arrayData)
        return rawRecs.map { raw in
            Recommendation(
                id: UUID(),
                parameterId: raw.parameterId,
                suggestedValue: raw.suggestedValue,
                rationale: raw.rationale,
                impact: Recommendation.Impact(rawValue: raw.impact) ?? .medium
            )
        }
    }
}

private struct ClaudeResponse: Codable {
    let content: [ContentBlock]
}

private struct ContentBlock: Codable {
    let type: String
    let text: String
}

private struct RawRecommendation: Codable {
    let parameterId: String
    let suggestedValue: String
    let rationale: String
    let impact: String
}

enum APIError: LocalizedError {
    case unauthorized
    case rateLimited
    case httpError(Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Invalid API key. Please check your Claude API key in Settings."
        case .rateLimited:
            return "Rate limited. Please wait a moment and try again."
        case .httpError(let code):
            return "HTTP error \(code)"
        case .invalidResponse:
            return "Failed to parse API response"
        }
    }
}
