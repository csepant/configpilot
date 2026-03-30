import Foundation

enum ConfigFormat: String, Codable {
    case ini
    case toml
    case keyvalue
    case lua
    case zshrc
    case json
    case yaml
}
