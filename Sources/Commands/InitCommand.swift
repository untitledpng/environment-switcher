import Foundation
import ArgumentParser

struct InitCommand: ParsableCommand {
    let globalConfig: GlobalConfig
    
    private struct ExtendConfiguration {
        let mode: String?
        let extendEnabled: Bool?
        let whitelist: [String]?
        let fileModes: [String: String]
    }

    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Initialize a new project by creating the .switchrc file."
    )

    init() {
        self.globalConfig = GlobalConfigService.shared.config
    }

    func run() throws {
        // TODO: Add --force support to override the existing .switchrc file

        if ConfigService.configExists() {
            printTitle("WARN", BadgeType.warning, "This project is already initialised")
            return
        }

        printTitle("INFO", BadgeType.info, "Initialize a new project")

        let environments = try askEnvironments()
        let files = try askFiles()
        let extendConfiguration = try askExtendConfiguration(files: files)
        let config = Config(
            current_environment: environments.first!,
            environments: generateEnvironmentModels(environments: environments),
            default_files: files,
            mode: extendConfiguration.mode,
            extend_enabled: extendConfiguration.extendEnabled,
            extend_whitelist: extendConfiguration.whitelist,
            file_modes: extendConfiguration.fileModes.isEmpty ? nil : extendConfiguration.fileModes
        )

        try config.save()

        printTitle("DONE", BadgeType.success, "Created .switchrc in current directory")
        print("  Configuration created with environments: \(environments.map { $0.cyan }.joined(separator: ", "))")
        print("  Files to switch: \(files.map { $0.yellow }.joined(separator: ", "))\n")

        try askGitIgnore(files: files)
        try askFileCreation(files: files, environments: environments, config: config)

        printLn()
    }

    private func generateEnvironmentModels(environments: [String]) -> [String: Environment] {
        var environmentModels: [String: Environment] = [:]

        for environment in environments {
            environmentModels[environment] = Environment(files: [])
        }

        return environmentModels
    }

    private func askEnvironments() throws -> [String] {
        printLn()
        print("  Which environments do you want to add?")
        print("  (comma-separated, default: \(self.globalConfig.default_environments.joined(separator: ",").dim))")
        print("  > ".cyan, terminator: "")

        let environmentsInput = readLine() ?? ""
        let environmentsString = environmentsInput.trimmingCharacters(in: .whitespaces).isEmpty
            ? self.globalConfig.default_environments.joined(separator: ",")
            : environmentsInput.trimmingCharacters(in: .whitespaces)

        let environments = environmentsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !environments.isEmpty else {
            throw InitCommandError.noEnvironmentsProvided
        }

        return environments
    }

    private func askFiles() throws -> [String] {
        printLn()
        print("  Which files should be switched?")
        print("  (comma-separated, default: \(self.globalConfig.default_files.joined(separator: ",").dim))")
        print("  > ".cyan, terminator: "")

        let filesInput = readLine() ?? ""
        let filesString = filesInput.trimmingCharacters(in: .whitespaces).isEmpty
            ? self.globalConfig.default_files.joined(separator: ",")
            : filesInput.trimmingCharacters(in: .whitespaces)

        let files = filesString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !files.isEmpty else {
            throw InitCommandError.noFilesProvided
        }

        return files
    }

    private func askExtendConfiguration(files: [String]) throws -> ExtendConfiguration {
        printLn()
        print("  Do you want to configure extend mode for this project? (y/n, default: \("n".dim))")
        print("  > ".cyan, terminator: "")

        let response = readLine() ?? ""
        let shouldConfigure = response.trimmingCharacters(in: .whitespaces).lowercased() == "y"

        guard shouldConfigure else {
            return ExtendConfiguration(mode: nil, extendEnabled: nil, whitelist: nil, fileModes: [:])
        }

        printTitle("WARN", BadgeType.warning, "ALPHA: Extend mode is experimental and may be buggy.")
        print("  Use with caution in production projects.")

        let globalMode = self.globalConfig.mode
        printLn()
        print("  Project mode override? (\("replace".dim)/\("extend".dim), default: use global \(globalMode.dim))")
        print("  > ".cyan, terminator: "")
        let modeInput = (readLine() ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let mode: String?
        if modeInput == "replace" || modeInput == "extend" {
            mode = modeInput
        } else {
            mode = nil
        }

        printLn()
        print("  Override extend enabled for this project? (y/n, default: use global \((self.globalConfig.extend_enabled ? "y" : "n").dim))")
        print("  > ".cyan, terminator: "")
        let enabledInput = (readLine() ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let extendEnabled: Bool?
        if enabledInput == "y" {
            extendEnabled = true
        } else if enabledInput == "n" {
            extendEnabled = false
        } else {
            extendEnabled = nil
        }

        printLn()
        print("  Project extend whitelist override? (comma-separated, default: use global \(self.globalConfig.extend_whitelist.joined(separator: ",").dim))")
        print("  > ".cyan, terminator: "")
        let whitelistInput = (readLine() ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let whitelist: [String]?
        if whitelistInput.isEmpty {
            whitelist = nil
        } else {
            let parsed = whitelistInput
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            whitelist = parsed
        }

        printLn()
        print("  Files that should always use extend in this project? (comma-separated from selected files, default: none)")
        print("  > ".cyan, terminator: "")
        let extendFilesInput = (readLine() ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let extendFiles = parseSelectedFiles(input: extendFilesInput, allowedFiles: files)

        printLn()
        print("  Files that should always use replace in this project? (comma-separated from selected files, default: none)")
        print("  > ".cyan, terminator: "")
        let replaceFilesInput = (readLine() ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let replaceFiles = parseSelectedFiles(input: replaceFilesInput, allowedFiles: files)

        var fileModes: [String: String] = [:]
        for file in extendFiles {
            fileModes[file] = "extend"
        }

        for file in replaceFiles {
            fileModes[file] = "replace"
        }

        return ExtendConfiguration(
            mode: mode,
            extendEnabled: extendEnabled,
            whitelist: whitelist,
            fileModes: fileModes
        )
    }

    private func parseSelectedFiles(input: String, allowedFiles: [String]) -> [String] {
        if input.isEmpty {
            return []
        }

        let selected = input
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let allowed = Set(allowedFiles)
        return selected.filter { allowed.contains($0) }
    }

    private func askGitIgnore(files: [String]) throws {
        printLn()

        let gitignorePath = ".gitignore"
        let gitignoreExists = FileManager.default.fileExists(atPath: gitignorePath)
        var gitignoreContent = ""
        var entriesToAdd: [String] = []

        let prompt = gitignoreExists
            ? "  Do you want to update your .gitignore with these files? (y/n, default: \("y".dim))"
            : "  The .gitignore doesn't exist. Do you want to create it? (y/n, default: \("y".dim))"

        print(prompt)
        print("  > ".cyan, terminator: "")

        let response = readLine() ?? ""
        let shouldUpdate = response.trimmingCharacters(in: .whitespaces).isEmpty
            || response.trimmingCharacters(in: .whitespaces).lowercased() == "y"

        guard shouldUpdate else {
            return
        }

        if gitignoreExists {
            gitignoreContent = try String(contentsOf: URL(fileURLWithPath: gitignorePath), encoding: .utf8)
        }

        if !gitignoreContent.contains(".switchrc") {
            entriesToAdd.append(".switchrc")
        }

        for file in files {
            if !gitignoreContent.contains(file) {
                entriesToAdd.append(file)
            }

            let pattern = "\(file).*"
            if !gitignoreContent.contains(pattern) {
                entriesToAdd.append(pattern)
            }
        }

        guard !entriesToAdd.isEmpty else {
            printTitle("DONE", BadgeType.success, "The .gitignore already contains all necessary entries")
            return
        }

        if gitignoreExists && !gitignoreContent.isEmpty && !gitignoreContent.hasSuffix("\n") {
            gitignoreContent += "\n"
        }

        if !gitignoreContent.isEmpty {
            gitignoreContent += "\n# Environment Switcher\n"
        } else {
            gitignoreContent = "# Environment Switcher\n"
        }

        gitignoreContent += entriesToAdd.joined(separator: "\n")
        gitignoreContent += "\n"

        try gitignoreContent.write(to: URL(fileURLWithPath: gitignorePath), atomically: true, encoding: .utf8)

        let action = gitignoreExists ? "Updated the .gitignore file" : "Created the .gitignore file"

        printTitle("DONE", BadgeType.success, action)

        for file in entriesToAdd {
            print("    \(file)".dim)
        }
    }

    private func askFileCreation(files: [String], environments: [String], config: Config) throws {
        printLn()
        print("  Do you want to create all environment-specific files? (y/n, default: \("y".dim))")
        print("  > ".cyan, terminator: "")

        let response = readLine() ?? ""
        let shouldCreate = response.trimmingCharacters(in: .whitespaces).isEmpty
            || response.trimmingCharacters(in: .whitespaces).lowercased() == "y"

        guard shouldCreate else {
            return
        }

        var createdFiles: [String] = []
        var skippedFiles: [String] = []

        for file in files {
            let originalFilePath = file
            let originalFileExists = FileManager.default.fileExists(atPath: originalFilePath)

            if !originalFileExists {
                try "# TODO: Add your configuration here".write(to: URL(fileURLWithPath: originalFilePath), atomically: true, encoding: .utf8)
                createdFiles.append(originalFilePath)
            }

            if shouldCreateDefaultFile(file: file, config: config) {
                let defaultFilePath = "\(file).default"
                if !FileManager.default.fileExists(atPath: defaultFilePath) {
                    let content = try String(contentsOf: URL(fileURLWithPath: originalFilePath), encoding: .utf8)
                    try content.write(to: URL(fileURLWithPath: defaultFilePath), atomically: true, encoding: .utf8)
                    createdFiles.append(defaultFilePath)
                } else {
                    skippedFiles.append(defaultFilePath)
                }
            }

            for env in environments {
                let content: String
                let envFilePath = "\(file).\(env)"

                if FileManager.default.fileExists(atPath: envFilePath) {
                    skippedFiles.append("\(file).\(env)")
                    continue
                }

                if originalFileExists {
                    content = try String(contentsOf: URL(fileURLWithPath: originalFilePath), encoding: .utf8)
                } else {
                    content = "# Environment: \(env)\n# TODO: Add your \(env) configuration here\n"
                }

                try content.write(to: URL(fileURLWithPath: envFilePath), atomically: true, encoding: .utf8)
                createdFiles.append("\(file).\(env)")
            }
        }

        if !createdFiles.isEmpty {
            printTitle("DONE", BadgeType.success, "Created \(createdFiles.count) environment file(s)")
            for file in createdFiles {
                print("    \(file)".dim)
            }
        }

        if !skippedFiles.isEmpty {
            printTitle("WARN", BadgeType.warning, "Skipped \(skippedFiles.count) existing file(s)")
            for file in skippedFiles {
                print("    \(file)".dim)
            }
        }
    }

    private func shouldCreateDefaultFile(file: String, config: Config) -> Bool {
        let mode = resolveFileSwitchMode(file: file, config: config, globalConfig: self.globalConfig)
        let extendEnabled = config.isExtendEnabled(globalConfig: self.globalConfig)
        let whitelist = config.effectiveExtendWhitelist(globalConfig: self.globalConfig)
        let isWhitelisted = isFileWhitelistedForExtend(file: file, whitelist: whitelist)
        let hasHandler = resolveExtendHandler(file: file) != nil

        return mode == .extend && extendEnabled && isWhitelisted && hasHandler
    }
}
