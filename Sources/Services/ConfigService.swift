import Foundation

struct ConfigService
{
    static var shared = ConfigService()
    static let configPath = "\(FileManager.default.currentDirectoryPath)/.switchrc"
    private(set) var config: Config
    
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
    
    private static func loadConfig() throws -> Config {
        if !self.configExists() {
            throw ConfigError.configNotFound
        }
        
        let data = try Data(contentsOf: URL(fileURLWithPath: self.configPath))
        let decoder = JSONDecoder()

        do {
            return try decoder.decode(Config.self, from: data)
        } catch {
            throw ConfigError.invalidConfig
        }
    }
}
