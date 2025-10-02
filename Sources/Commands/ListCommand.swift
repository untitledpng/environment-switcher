import Foundation

class ListCommand {
    let fm = FileManager.default
    let currentDir = FileManager.default.currentDirectoryPath

    func execute() throws {
        let config = try loadConfig()

        print("Available environments:\n".bold)

        if let files = config.files {
            print("Default files: \(files.joined(separator: ", ").dim)\n")
        }

        for (name, _) in config.environments.sorted(by: { $0.key < $1.key }) {
            let files = config.getFiles(for: name)
            print("• \(name.cyan.bold)")
            print("  Files: \(files.joined(separator: ", ").dim)")
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
