import Foundation

struct SwitchConfig: Codable {
    var environments: [String: EnvironmentConfig]
    var currentEnvironment: String?
    var files: [String]?

    func getFiles(for environment: String) -> [String] {
        if let envConfig = environments[environment] {
            var allFiles: [String] = []

            // Add default files first (if they exist)
            if let defaultFiles = files {
                allFiles.append(contentsOf: defaultFiles)
            }

            // Add environment-specific files (if they exist)
            if let envFiles = envConfig.files {
                allFiles.append(contentsOf: envFiles)
            }

            return allFiles
        }
        return []
    }
}

struct EnvironmentConfig: Codable {
    let files: [String]?
}
