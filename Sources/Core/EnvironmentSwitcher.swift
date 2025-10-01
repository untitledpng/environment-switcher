import Foundation

class EnvironmentSwitcher {
    let fm = FileManager.default
    let currentDir = FileManager.default.currentDirectoryPath

    func switchEnvironment(to environment: String) throws {
        let config = try loadConfig()

        guard let envConfig = config.environments[environment] else {
            throw SwitchError.environmentNotFound(environment)
        }

        print("Switching to '\(environment)' environment...")

        for filePath in envConfig.files {
            try switchFile(filePath, to: environment)
        }

        print("✓ Successfully switched to '\(environment)'")
    }

    func listEnvironments() throws {
        let config = try loadConfig()

        print("Available environments:")
        for (name, envConfig) in config.environments.sorted(by: { $0.key < $1.key }) {
            print("\n• \(name)")
            print("  Files: \(envConfig.files.joined(separator: ", "))")
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

        print("✓ Created .switchrc in current directory")
        print("\nExample configuration created with 'local', 'staging' and 'production' environments.")
        print("Edit .switchrc to customize your environments and files.")
        print("\nNext steps:")
        print("1. Create environment-specific files (e.g., .env.local, .env.development, .env.production)")
        print("2. Run 'switch --list' to see available environments")
        print("3. Run 'switch <environment>' to switch between environments")
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

    private func switchFile(_ filePath: String, to environment: String) throws {
        let fullPath = "\(currentDir)/\(filePath)"
        let backupPath = "\(fullPath).backup"
        let envPath = "\(fullPath).\(environment)"

        guard fm.fileExists(atPath: envPath) else {
            print("⚠ Skipping '\(filePath)': \(filePath).\(environment) not found")
            return
        }

        if fm.fileExists(atPath: fullPath) {
            if fm.fileExists(atPath: backupPath) {
                try fm.removeItem(atPath: backupPath)
            }

            try fm.moveItem(atPath: fullPath, toPath: backupPath)
            print("  • Backed up: \(filePath) → \(filePath).backup")
        }

        try fm.copyItem(atPath: envPath, toPath: fullPath)
        print("  • Activated: \(filePath).\(environment) → \(filePath)")
    }
}
