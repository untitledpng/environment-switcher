import Foundation

struct GlobalConfigService
{
    static var shared = GlobalConfigService()
    static var configPath: String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(homeDir)/.config/switch/.switchrc"
    }
    
    private(set) var config: GlobalConfig
    
    static func configExists() -> Bool
    {
        return FileManager.default.fileExists(atPath: self.configPath)
    }
    
    private init() {
        do {
            self.config = try Self.loadConfig()
        } catch {
            print("Error: ".red + error.localizedDescription)
            exit(1)
        }
    }
    
    private static func loadConfig() throws -> GlobalConfig {
        if !self.configExists() {
            return GlobalConfig()
        }
        
        let data = try Data(contentsOf: URL(fileURLWithPath: self.configPath))
        let decoder = JSONDecoder()

        do {
            return try decoder.decode(GlobalConfig.self, from: data)
        } catch {
            throw ConfigError.invalidConfig
        }
    }
}
