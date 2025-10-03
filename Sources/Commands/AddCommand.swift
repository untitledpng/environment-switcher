import Foundation

class AddCommand {
    let fm = FileManager.default
    let currentDir = FileManager.default.currentDirectoryPath

    func execute() throws {
        let configPath = "\(currentDir)/.switchrc"

        guard fm.fileExists(atPath: configPath) else {
            throw SwitchError.configNotFound
        }

        // Load existing config
        var config = try loadConfig()

        // Prompt for environment name
        print("Enter the name of the new environment:".bold)
        print("> ".cyan, terminator: "")

        guard let environmentName = readLine()?.trimmingCharacters(in: .whitespaces), !environmentName.isEmpty else {
            throw SwitchError.custom("Environment name cannot be empty")
        }

        // Check if environment already exists
        if config.environments[environmentName] != nil {
            throw SwitchError.custom("Environment '\(environmentName)' already exists")
        }

        // Check if config has default files
        let hasDefaultFiles = config.files != nil && !(config.files?.isEmpty ?? true)

        var files: [String] = []

        if hasDefaultFiles {
            // Ask if user wants to use default files
            print("\nThis configuration uses default files: \(config.files!.joined(separator: ", ").cyan)")
            print("Do you want to use these files for '\(environmentName)'? (y/n, default: \("y".dim))")
            print("> ".cyan, terminator: "")

            let response = readLine()?.trimmingCharacters(in: .whitespaces) ?? ""
            let useDefaultFiles = response.isEmpty || response.lowercased() == "y"

            if !useDefaultFiles {
                // Ask for environment-specific files
                files = try promptForFiles()
            }
            // If using default files, leave files empty
        } else {
            // No default files, must specify files
            files = try promptForFiles()
        }

        // Add new environment to config
        config.environments[environmentName] = EnvironmentConfig(files: files.isEmpty ? [] : files)

        // Save updated config
        try saveConfig(config)

        print("\n ⏺ Added environment '\(environmentName.cyan.bold)' to .switchrc".green)

        if hasDefaultFiles && files.isEmpty {
            print("   Using default files: \(config.files!.joined(separator: ", ").dim)")
        } else if !files.isEmpty {
            print("   Files: \(files.joined(separator: ", ").dim)")
        }

        // Handle environment file creation
        let filesToCreate = hasDefaultFiles && files.isEmpty ? config.files! : files
        try handleEnvironmentFileCreation(files: filesToCreate, environment: environmentName)
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

    private func promptForFiles() throws -> [String] {
        // Load global config defaults if available
        let globalConfig = GlobalConfig.shared
        let suggestedFiles = globalConfig.initDefaults?.files ?? [".env"]

        print("\nWhich files should be switched for this environment?")
        print("(comma-separated, default: \(suggestedFiles.joined(separator: ",").dim))")
        print("> ".cyan, terminator: "")

        let filesInput = readLine() ?? ""
        let filesString = filesInput.trimmingCharacters(in: .whitespaces).isEmpty
            ? suggestedFiles.joined(separator: ",")
            : filesInput.trimmingCharacters(in: .whitespaces)

        let files = filesString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !files.isEmpty else {
            throw SwitchError.custom("No files specified")
        }

        return files
    }

    private func handleEnvironmentFileCreation(files: [String], environment: String) throws {
        print("\nDo you want to create environment-specific files for '\(environment.cyan)'? (y/n, default: \("y".dim))")
        print("> ".cyan, terminator: "")

        let response = readLine() ?? ""
        let shouldCreate = response.trimmingCharacters(in: .whitespaces).isEmpty
            || response.trimmingCharacters(in: .whitespaces).lowercased() == "y"

        guard shouldCreate else {
            return
        }

        var createdFiles: [String] = []
        var skippedFiles: [String] = []

        for file in files {
            let originalFilePath = "\(currentDir)/\(file)"
            let originalFileExists = fm.fileExists(atPath: originalFilePath)
            let envFilePath = "\(currentDir)/\(file).\(environment)"

            if fm.fileExists(atPath: envFilePath) {
                skippedFiles.append("\(file).\(environment)")
                continue
            }

            // Create file with content from original file if it exists, otherwise use a comment
            let content: String
            if originalFileExists {
                content = try String(contentsOf: URL(fileURLWithPath: originalFilePath), encoding: .utf8)
            } else {
                content = "# Environment: \(environment)\n# TODO: Add your \(environment) configuration here\n"
            }

            try content.write(to: URL(fileURLWithPath: envFilePath), atomically: true, encoding: .utf8)
            createdFiles.append("\(file).\(environment)")
        }

        if !createdFiles.isEmpty {
            print("\n ⏺ Created \(createdFiles.count) environment file(s):".green)
            for file in createdFiles {
                print("   • \(file.yellow)")
            }
        }

        if !skippedFiles.isEmpty {
            print("\n ⏺ Skipped \(skippedFiles.count) existing file(s):".dim)
            for file in skippedFiles {
                print("   • \(file)")
            }
        }
    }
}
