import Foundation

struct Recommendation: Identifiable, Codable {
    let id: UUID
    let parameterId: String
    let suggestedValue: String
    let rationale: String
    let impact: Impact

    enum Impact: String, Codable {
        case low, medium, high
    }
}
