import Foundation

struct GlobalConfig: Codable {
    var default_environments: [String] = ["local", "staging", "production"]
    var default_files: [String] = [".env"]
    
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
