import Foundation

struct SwitchConfig: Codable {
    let environments: [String: EnvironmentConfig]
}

struct EnvironmentConfig: Codable {
    let files: [String]
}
