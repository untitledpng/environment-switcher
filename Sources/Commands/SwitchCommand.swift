import Foundation

class SwitchCommand {
    let fm = FileManager.default
    let currentDir = FileManager.default.currentDirectoryPath

    func execute(environment: String) throws {
        let config = try loadConfig()

        guard let envConfig = config.environments[environment] else {
            throw SwitchError.environmentNotFound(environment)
        }

        print("\("Switching to '".bold)\(environment.cyan.bold)\("' environment...".bold)")

        var successCount = 0
        for filePath in envConfig.files {
            if try switchFile(filePath, to: environment) {
                successCount += 1
            }
        }

        if successCount > 0 {
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
