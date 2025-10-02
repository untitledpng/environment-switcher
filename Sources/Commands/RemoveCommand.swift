import Foundation

class RemoveCommand {
    let fm = FileManager.default
    let currentDir = FileManager.default.currentDirectoryPath

    func execute() throws {
        let configPath = "\(currentDir)/.switchrc"

        guard fm.fileExists(atPath: configPath) else {
            throw SwitchError.configNotFound
        }

        // Load existing config
        var config = try loadConfig()

        // Check if there are any environments
        guard !config.environments.isEmpty else {
            print(" ⏺ No environments found in .switchrc".yellow)
            return
        }

        // Show available environments
        print("Available environments:".bold)
        for (name, _) in config.environments.sorted(by: { $0.key < $1.key }) {
            print("  • \(name.cyan)")
        }

        // Prompt for environment name
        print("\nEnter the name of the environment to remove:".bold)
        print("> ".cyan, terminator: "")

        guard let environmentName = readLine()?.trimmingCharacters(in: .whitespaces), !environmentName.isEmpty else {
            throw SwitchError.custom("Environment name cannot be empty")
        }

        // Check if environment exists
        guard config.environments[environmentName] != nil else {
            throw SwitchError.environmentNotFound(environmentName)
        }

        // Confirm deletion
        print("\nAre you sure you want to remove '\(environmentName.red)'? (y/n)")
        print("> ".cyan, terminator: "")

        let confirmation = readLine()?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""

        guard confirmation == "y" || confirmation == "yes" else {
            print("\n ⏺ Cancelled. Environment '\(environmentName)' was not removed.".dim)
            return
        }

        // Remove environment
        config.environments.removeValue(forKey: environmentName)

        // Clear currentEnvironment if it was the removed one
        if config.currentEnvironment == environmentName {
            config.currentEnvironment = nil
        }

        // Save updated config
        try saveConfig(config)

        print("\n ⏺ Removed environment '\(environmentName.cyan)' from .switchrc".green)
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

    private func saveConfig(_ config: SwitchConfig) throws {
        let configPath = "\(currentDir)/.switchrc"

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: URL(fileURLWithPath: configPath))
    }
}
