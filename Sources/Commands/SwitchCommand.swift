import Foundation

class SwitchCommand {
    let fm = FileManager.default
    let currentDir = FileManager.default.currentDirectoryPath

    func execute(environment: String) throws {
        let config = try loadConfig()

        guard config.environments[environment] != nil else {
            throw SwitchError.environmentNotFound(environment)
        }

        let files = config.getFiles(for: environment)

        if files.isEmpty && (config.files == nil || config.files?.isEmpty == true) {
            throw SwitchError.custom("No files configured for environment '\(environment)'")
        }

        print("\("Switching to '".bold)\(environment.cyan.bold)\("' environment...".bold)")

        var successCount = 0
        for filePath in files {
            if try switchFile(filePath, to: environment) {
                successCount += 1
            }
        }

        if successCount > 0 {
            try updateConfigWithCurrentEnvironment(environment)
            print("\n ⏺ Successfully switched to '\(environment.cyan.bold)'".green)
        } else {
            print("\n ⏺ No files were switched. Please ensure environment-specific files exist.".red)
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

    private func updateConfigWithCurrentEnvironment(_ environment: String) throws {
        let configPath = "\(currentDir)/.switchrc"
        var config = try loadConfig()
        config.currentEnvironment = environment

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: URL(fileURLWithPath: configPath))
    }

    private func switchFile(_ filePath: String, to environment: String) throws -> Bool {
        let fullPath = "\(currentDir)/\(filePath)"
        let backupPath = "\(fullPath).backup"
        let envPath = "\(fullPath).\(environment)"

        print(" • Processing \(filePath)...")

        guard fm.fileExists(atPath: envPath) else {
            print("   ⎿ Skipping '\(filePath.yellow)': \(filePath).\(environment) not found".dim)
            return false
        }

        if fm.fileExists(atPath: fullPath) {
            if fm.fileExists(atPath: backupPath) {
                try fm.removeItem(atPath: backupPath)
            }

            try fm.moveItem(atPath: fullPath, toPath: backupPath)
            print("   ⎿ Backed up: \(filePath.dim) → \("\(filePath).backup".dim)")
        }

        try fm.copyItem(atPath: envPath, toPath: fullPath)
        print("     Activated: \("\(filePath).\(environment)".brightCyan) → \(filePath.bold)")
        return true
    }
}
