import Foundation

class InitCommand {
    let fm = FileManager.default
    let currentDir = FileManager.default.currentDirectoryPath

    func execute() throws {
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
            envConfigs[env] = EnvironmentConfig(files: [])
        }

        let config = SwitchConfig(environments: envConfigs, currentEnvironment: nil, files: files)

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

    // MARK: - Private Methods

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
}
