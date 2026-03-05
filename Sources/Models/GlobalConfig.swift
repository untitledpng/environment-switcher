import Foundation

struct GlobalConfig: Codable {
    var default_environments: [String] = ["local", "staging", "production"]
    var default_files: [String] = [".env"]
    var mode: String = "replace"
    var extend_enabled: Bool = false
    var extend_whitelist: [String] = []
    var file_modes: [String: String] = [:]
    var post_switch: [String] = []

    enum CodingKeys: String, CodingKey {
        case default_environments
        case default_files
        case mode
        case extend_enabled
        case extend_whitelist
        case file_modes
        case post_switch
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.default_environments = try container.decodeIfPresent([String].self, forKey: .default_environments) ?? ["local", "staging", "production"]
        self.default_files = try container.decodeIfPresent([String].self, forKey: .default_files) ?? [".env"]
        self.mode = try container.decodeIfPresent(String.self, forKey: .mode) ?? "replace"
        self.extend_enabled = try container.decodeIfPresent(Bool.self, forKey: .extend_enabled) ?? false
        self.extend_whitelist = try container.decodeIfPresent([String].self, forKey: .extend_whitelist) ?? []
        self.file_modes = try container.decodeIfPresent([String: String].self, forKey: .file_modes) ?? [:]
        self.post_switch = try container.decodeIfPresent([String].self, forKey: .post_switch) ?? []
    }
    
    func save() throws {
        let path = GlobalConfigService.configPath
        let directory = (path as NSString).deletingLastPathComponent

        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(self)
        
        let fileURL = URL(fileURLWithPath: path)
        try jsonData.write(to: fileURL, options: .atomic)
    }
}
