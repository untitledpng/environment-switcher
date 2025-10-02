import Foundation

class EnvironmentSwitcher {
    let fm = FileManager.default
    let currentDir = FileManager.default.currentDirectoryPath

    func switchEnvironment(to environment: String) throws {
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

    func listEnvironments() throws {
        let config = try loadConfig()

        print("Available environments:\n".bold)
        for (name, envConfig) in config.environments.sorted(by: { $0.key < $1.key }) {
            print("• \(name.cyan.bold)")
            print("  Files: \(envConfig.files.joined(separator: ", ").dim)")
        }
    }

    func showCurrentEnvironment() throws {
        let config = try loadConfig()
        let current = try detectCurrentEnvironment(config: config)

        print("Current environment: ".bold, terminator: "")

        switch current {
        case .matched(let envName, let allFiles):
            print(envName.cyan.bold)
            for file in allFiles {
                print("  ⎿  \(file)")
            }
        case .modified(let envName, let matchedFiles, let modifiedFiles):
            print("\(envName.yellow.bold) (modified)".yellow)
            for file in matchedFiles {
                print("  ⎿  \(file)")
            }
            for file in modifiedFiles {
                print("  ⎿  \("\(file) (modified)".brightYellow)")
            }
        case .unknown:
            print("unknown".dim)
        }

        print("\nAvailable environments:".bold)
        for (name, envConfig) in config.environments.sorted(by: { $0.key < $1.key }) {
            print(" • \(name.cyan.bold)")
            print("  ⎿  Files: \(envConfig.files.joined(separator: ", ").dim)")
        }
    }

    enum EnvironmentStatus {
        case matched(String, [String])
        case modified(String, [String], [String])
        case unknown
    }

    private func detectCurrentEnvironment(config: SwitchConfig) throws -> EnvironmentStatus {
        var bestMatch: (name: String, matchCount: Int, totalFiles: Int, matchedFiles: [String], modifiedFiles: [String]) = ("", 0, 0, [], [])

        for (envName, envConfig) in config.environments {
            var matchCount = 0
            var matchedFiles: [String] = []
            var modifiedFiles: [String] = []
            let totalFiles = envConfig.files.count

            for filePath in envConfig.files {
                let fullPath = "\(currentDir)/\(filePath)"
                let envPath = "\(fullPath).\(envName)"

                guard fm.fileExists(atPath: fullPath), fm.fileExists(atPath: envPath) else {
                    continue
                }

                if try filesAreIdentical(fullPath, envPath) {
                    matchCount += 1
                    matchedFiles.append(filePath)
                } else {
                    modifiedFiles.append(filePath)
                }
            }

            if matchCount > bestMatch.matchCount {
                bestMatch = (envName, matchCount, totalFiles, matchedFiles, modifiedFiles)
            }
        }

        if bestMatch.matchCount == 0 {
            return .unknown
        } else if bestMatch.matchCount == bestMatch.totalFiles {
            return .matched(bestMatch.name, bestMatch.matchedFiles)
        } else {
            return .modified(bestMatch.name, bestMatch.matchedFiles, bestMatch.modifiedFiles)
        }
    }

    private func filesAreIdentical(_ path1: String, _ path2: String) throws -> Bool {
        let data1 = try Data(contentsOf: URL(fileURLWithPath: path1))
        let data2 = try Data(contentsOf: URL(fileURLWithPath: path2))
        return data1 == data2
    }

    func initializeConfig() throws {
        let configPath = "\(currentDir)/.switchrc"

        guard !fm.fileExists(atPath: configPath) else {
            throw SwitchError.configAlreadyExists
        }

        print("Let's set up your environment switcher configuration.\n".bold)

        // Prompt for environments
        print("Which environments do you want to add?")
        print("(comma-separated, default: \("local,staging,production".dim))")
        print("> ".cyan, terminator: "")

        let environmentsInput = readLine() ?? ""
        let environmentsString = environmentsInput.trimmingCharacters(in: .whitespaces).isEmpty
            ? "local,staging,production"
            : environmentsInput.trimmingCharacters(in: .whitespaces)

        let environments = environmentsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !environments.isEmpty else {
            throw SwitchError.custom("No environments specified")
        }

        // Prompt for files
        print("\nWhich files should be switched?")
        print("(comma-separated, default: \(".env".dim))")
        print("> ".cyan, terminator: "")

        let filesInput = readLine() ?? ""
        let filesString = filesInput.trimmingCharacters(in: .whitespaces).isEmpty
            ? ".env"
            : filesInput.trimmingCharacters(in: .whitespaces)

        let files = filesString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !files.isEmpty else {
            throw SwitchError.custom("No files specified")
        }

        // Build config
        var envConfigs: [String: EnvironmentConfig] = [:]
        for env in environments {
            envConfigs[env] = EnvironmentConfig(files: files)
        }

        let config = SwitchConfig(environments: envConfigs)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)

        try data.write(to: URL(fileURLWithPath: configPath))

        print("\n ⏺ Created .switchrc in current directory\n".green)
        print("Configuration created with environments: \(environments.map { $0.cyan }.joined(separator: ", "))")
        print("Files to switch: \(files.map { $0.yellow }.joined(separator: ", "))\n")

        // Handle .gitignore
        try handleGitignoreUpdate(files: files)

        // Handle environment file creation
        try handleEnvironmentFileCreation(files: files, environments: environments)

        print("\nNext steps:".bold)
        print("1. Edit your environment-specific files with the appropriate configuration")
        print("2. Run '\("switch --list".cyan)' to see available environments")
        print("3. Run '\("switch <environment>".cyan)' to switch between environments")
    }

    private func handleGitignoreUpdate(files: [String]) throws {
        let gitignorePath = "\(currentDir)/.gitignore"
        let gitignoreExists = fm.fileExists(atPath: gitignorePath)

        let prompt = gitignoreExists
            ? "\nDo you want to update your .gitignore with these files? (y/n, default: \("y".dim))"
            : "\n.gitignore doesn't exist. Do you want to create it? (y/n, default: \("y".dim))"

        print(prompt)
        print("> ".cyan, terminator: "")

        let response = readLine() ?? ""
        let shouldUpdate = response.trimmingCharacters(in: .whitespaces).isEmpty
            || response.trimmingCharacters(in: .whitespaces).lowercased() == "y"

        guard shouldUpdate else {
            return
        }

        var gitignoreContent = ""

        // Read existing content if file exists
        if gitignoreExists {
            gitignoreContent = try String(contentsOf: URL(fileURLWithPath: gitignorePath), encoding: .utf8)
        }

        // Prepare entries to add
        var entriesToAdd: [String] = []

        // Add .switchrc if not already present
        if !gitignoreContent.contains(".switchrc") {
            entriesToAdd.append(".switchrc")
        }

        // Add file patterns (file.*)
        for file in files {
            let pattern = "\(file).*"
            if !gitignoreContent.contains(pattern) {
                entriesToAdd.append(pattern)
            }
        }

        guard !entriesToAdd.isEmpty else {
            print("✓ .gitignore already contains all necessary entries".dim)
            return
        }

        // Ensure file ends with newline before appending
        if gitignoreExists && !gitignoreContent.isEmpty && !gitignoreContent.hasSuffix("\n") {
            gitignoreContent += "\n"
        }

        // Add a section header if we're adding entries
        if !gitignoreContent.isEmpty {
            gitignoreContent += "\n# Environment Switcher\n"
        } else {
            gitignoreContent = "# Environment Switcher\n"
        }

        gitignoreContent += entriesToAdd.joined(separator: "\n")
        gitignoreContent += "\n"

        // Write to file
        try gitignoreContent.write(to: URL(fileURLWithPath: gitignorePath), atomically: true, encoding: .utf8)

        let action = gitignoreExists ? "Updated" : "Created"
        print(" ⏺ \(action) .gitignore with entries: \(entriesToAdd.map { $0.yellow }.joined(separator: ", "))".green)
    }

    private func handleEnvironmentFileCreation(files: [String], environments: [String]) throws {
        print("\nDo you want to create all environment-specific files? (y/n, default: \("y".dim))")
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
            for env in environments {
                let envFilePath = "\(currentDir)/\(file).\(env)"

                if fm.fileExists(atPath: envFilePath) {
                    skippedFiles.append("\(file).\(env)")
                    continue
                }

                // Create empty file with a comment
                let content = "# Environment: \(env)\n# TODO: Add your \(env) configuration here\n"
                try content.write(to: URL(fileURLWithPath: envFilePath), atomically: true, encoding: .utf8)
                createdFiles.append("\(file).\(env)")
            }
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
