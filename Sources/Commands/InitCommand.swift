import Foundation
import ArgumentParser

struct InitCommand: ParsableCommand {
    let globalConfig: GlobalConfig
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
        let config = Config(
            current_environment: environments.first!,
            environments: generateEnvironmentModels(environments: environments),
            default_files: files
        )

        try config.save()

        printTitle("DONE", BadgeType.success, "Created .switchrc in current directory")
        print("  Configuration created with environments: \(environments.map { $0.cyan }.joined(separator: ", "))")
        print("  Files to switch: \(files.map { $0.yellow }.joined(separator: ", "))\n")

        try askGitIgnore(files: files)
        try askFileCreation(files: files, environments: environments)

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

    private func askFileCreation(files: [String], environments: [String]) throws {
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
}
