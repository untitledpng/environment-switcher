import Foundation

struct InitDefaults: Codable {
    var environments: [String]?
    var files: [String]?
}

struct GlobalConfig: Codable {
    var initDefaults: InitDefaults?

    // Shared instance - loaded lazily
    private static var _shared: GlobalConfig?
    static var shared: GlobalConfig {
        if let config = _shared {
            return config
        }
        let loaded = load() ?? GlobalConfig()
        _shared = loaded
        return loaded
    }

    static func globalConfigPath() -> String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(homeDir)/.config/switch/.switchrc"
    }

    static func load() -> GlobalConfig? {
        let path = globalConfigPath()

        guard FileManager.default.fileExists(atPath: path) else {
            return nil
        }

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(GlobalConfig.self, from: data)
    }

    func save() throws {
        let path = GlobalConfig.globalConfigPath()
        let directory = (path as NSString).deletingLastPathComponent

        // Create directory if it doesn't exist
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: URL(fileURLWithPath: path))
    }
}
