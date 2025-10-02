import Foundation

class ListCommand {
    let fm = FileManager.default
    let currentDir = FileManager.default.currentDirectoryPath

    func execute() throws {
        let config = try loadConfig()

        print("Available environments:\n".bold)
        for (name, envConfig) in config.environments.sorted(by: { $0.key < $1.key }) {
            print("• \(name.cyan.bold)")
            print("  Files: \(envConfig.files.joined(separator: ", ").dim)")
        }
    }

    // MARK: - Private Methods

    private func loadConfig() throws -> SwitchConfig {
        let configPath = "\(currentDir)/.switchrc"

        guard fm.fileExists(atPath: configPath) else {
            throw SwitchError.configNotFound
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
        let decoder = JSONDecoder()

        do {
            return try decoder.decode(SwitchConfig.self, from: data)
        } catch {
            throw SwitchError.invalidConfig
        }
    }
}
