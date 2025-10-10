import ArgumentParser
import Foundation

struct SaveCommand: ParsableCommand {
    var config: Config

    static let configuration = CommandConfiguration(
        commandName: "save",
        abstract: "Save changes from active files to current environment-specific files"
    )

    init() {
        self.config = ConfigService.shared.config
    }

    func run() throws {
        let fileManager = FileManager.default
        let files = self.config.getFiles()
        let currentEnvironment = self.config.current_environment

        if files.isEmpty {
            printTitle("ERROR", BadgeType.error, "No files configured for this environment.")
            printLn()
            return
        }

        // Check which files are modified
        var modifiedFiles: [String] = []
        var unmodifiedFiles: [String] = []
        var missingFiles: [String] = []

        for file in files {
            let status = getFileStatus(file: file, environment: currentEnvironment)

            switch status {
                case .modified:
                    modifiedFiles.append(file)
                case .original:
                    unmodifiedFiles.append(file)
                case .notFound:
                    missingFiles.append(file)
            }
        }

        if modifiedFiles.isEmpty {
            printTitle("INFO", BadgeType.info, "No modified files to save.")

            if !unmodifiedFiles.isEmpty {
                print("  All files are up to date with the \(currentEnvironment) environment.")
            }

            printLn()
            return
        }

        // Show what will be saved and ask for confirmation
        printLn()
        printTitle("INFO", BadgeType.info, "The following files will be saved to the \(currentEnvironment.cyan) environment:")

        for file in modifiedFiles {
            let envPath = getFileEnvironmentPath(file: file, environment: currentEnvironment)
            print("    \(file) \("→".dim) \(envPath)".yellow)
        }

        printLn()
        print("  This will \("overwrite".bold.yellow) the environment-specific files with the current active versions.")
        printLn()

        print("  Do you want to continue? (y/n, default: \("y".dim))")
        print("  > ".cyan, terminator: "")

        let response = readLine() ?? ""
        let shouldContinue = response.trimmingCharacters(in: .whitespaces).isEmpty
            || response.trimmingCharacters(in: .whitespaces).lowercased() == "y"

        guard shouldContinue else {
            printLn()
            printTitle("INFO", BadgeType.info, "Save cancelled.")
            printLn()
            return
        }

        printLn()
        printTitle("INFO", BadgeType.info, "Saving changes to the \(currentEnvironment) environment.")

        var savedFiles: [String] = []
        var failedFiles: [String] = []

        for file in modifiedFiles {
            let envPath = getFileEnvironmentPath(file: file, environment: currentEnvironment)
            let label = "\("Copying file".dim) [\(file)] \("to".dim) [\(envPath)]"
            printUpdatableDotLine(label: label, value: "RUNNING".bold.dim)

            do {
                if fileManager.fileExists(atPath: envPath) {
                    try fileManager.removeItem(atPath: envPath)
                }

                try fileManager.copyItem(atPath: file, toPath: envPath)
                savedFiles.append(file)
                printUpdatableDotLine(label: label, value: "DONE".bold.green, closeLine: true)
            } catch {
                failedFiles.append(file)
                printUpdatableDotLine(label: label, value: "FAILED".bold.red, closeLine: true)
            }
        }

        printLn()

        if !savedFiles.isEmpty {
            printTitle("DONE", BadgeType.success, "Saved \(savedFiles.count) file(s) to \(currentEnvironment)")
            for file in savedFiles {
                print("    \(file)".green)
            }
            printLn()
        }

        if !unmodifiedFiles.isEmpty {
            printTitle("INFO", BadgeType.info, "Skipped \(unmodifiedFiles.count) unmodified file(s)")
            for file in unmodifiedFiles {
                print("    \(file)".dim)
            }
            printLn()
        }

        if !missingFiles.isEmpty {
            printTitle("WARN", BadgeType.warning, "Skipped \(missingFiles.count) missing file(s)")
            for file in missingFiles {
                print("    \(file)".dim)
            }
            printLn()
        }

        if !failedFiles.isEmpty {
            printTitle("ERROR", BadgeType.error, "Failed to save \(failedFiles.count) file(s)")
            for file in failedFiles {
                print("    \(file)".red)
            }
            printLn()
        }
    }
}
