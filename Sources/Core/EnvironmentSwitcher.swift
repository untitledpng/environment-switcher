import Foundation

class EnvironmentSwitcher {
    let fm = FileManager.default
    let currentDir = FileManager.default.currentDirectoryPath

    func switchEnvironment(to environment: String) throws {
        let config = try loadConfig()

        guard let envConfig = config.environments[environment] else {
            throw SwitchError.environmentNotFound(environment)
        }

        print("Switching to '\(environment.cyan.bold)' environment...".dim)

        var successCount = 0
        for filePath in envConfig.files {
            if try switchFile(filePath, to: environment) {
                successCount += 1
            }
        }

        if successCount > 0 {
            print("\n✅ Successfully switched to '\(environment.cyan.bold)'".green)
        } else {
            print("\n❌ No files were switched. Please ensure environment-specific files exist.".red)
        }
    }

    func listEnvironments() throws {
        let config = try loadConfig()

        print("Available environments:\n".bold)
        for (name, envConfig) in config.environments.sorted(by: { $0.key < $1.key }) {
            print("• \(name.cyan.bold)")
            print("  Files: \(envConfig.files.joined(separator: ", ").dim)")
        }
    }

    func initializeConfig() throws {
        let configPath = "\(currentDir)/.switchrc"

        guard !fm.fileExists(atPath: configPath) else {
            throw SwitchError.configAlreadyExists
        }

        let exampleConfig = SwitchConfig(
            environments: [
                "local": EnvironmentConfig(files: [".env"]),
                "staging": EnvironmentConfig(files: [".env"]),
                "production": EnvironmentConfig(files: [".env"])
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(exampleConfig)

        try data.write(to: URL(fileURLWithPath: configPath))

        print("✅ Created .switchrc in current directory\n".green)
        print("Example configuration created with '\("local".cyan)', '\("staging".cyan)' and '\("production".cyan)' environments.")
        print("Edit \(".switchrc".yellow) to customize your environments and files.\n")
        print("Next steps:".bold)
        print("1. Create environment-specific files (e.g., \(".env.local".dim), \(".env.staging".dim), \(".env.production".dim))")
        print("2. Run '\("switch --list".cyan)' to see available environments")
        print("3. Run '\("switch <environment>".cyan)' to switch between environments")
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

    private func switchFile(_ filePath: String, to environment: String) throws -> Bool {
        let fullPath = "\(currentDir)/\(filePath)"
        let backupPath = "\(fullPath).backup"
        let envPath = "\(fullPath).\(environment)"

        guard fm.fileExists(atPath: envPath) else {
            print("⚠️  Skipping '\(filePath.yellow)': \(filePath).\(environment) not found".dim)
            return false
        }

        if fm.fileExists(atPath: fullPath) {
            if fm.fileExists(atPath: backupPath) {
                try fm.removeItem(atPath: backupPath)
            }

            try fm.moveItem(atPath: fullPath, toPath: backupPath)
            print("  💾 Backed up: \(filePath.dim) → \("\(filePath).backup".dim)")
        }

        try fm.copyItem(atPath: envPath, toPath: fullPath)
        print("  ✅ Activated: \("\(filePath).\(environment)".brightCyan) → \(filePath.bold)")
        return true
    }
}
