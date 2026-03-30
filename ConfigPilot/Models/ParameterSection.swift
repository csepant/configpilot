import Foundation

struct ParameterSection: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let parameters: [Parameter]
}
