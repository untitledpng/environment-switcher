import ArgumentParser
import Foundation

struct RollbackCommand: ParsableCommand {
    var config: Config

    static let configuration = CommandConfiguration(
        commandName: "rollback",
        abstract: "Rollback changes to environment files from backup or environment-specific files"
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

        // Check what rollback sources are available for each file
        var filesWithBackup: [String] = []
        var filesWithEnvironment: [String] = []
        var filesWithBoth: [String] = []
        var filesWithNone: [String] = []

        for file in files {
            let backupPath = "\(file).backup"
            let environmentPath = getFileEnvironmentPath(file: file, environment: currentEnvironment)

            let hasBackup = fileManager.fileExists(atPath: backupPath)
            let hasEnvironment = fileManager.fileExists(atPath: environmentPath)

            if hasBackup && hasEnvironment {
                filesWithBoth.append(file)
            } else if hasBackup {
                filesWithBackup.append(file)
            } else if hasEnvironment {
                filesWithEnvironment.append(file)
            } else {
                filesWithNone.append(file)
            }
        }

        if filesWithBackup.isEmpty && filesWithEnvironment.isEmpty && filesWithBoth.isEmpty {
            printTitle("WARN", BadgeType.warning, "No rollback sources found.")
            print("  Backup files are created when you switch environments.")
            print("  Environment-specific files are created during initialization.")
            printLn()
            return
        }

        // Determine rollback source
        var rollbackSource: String

        if !filesWithBoth.isEmpty {
            // Ask user to choose source when both options exist
            printLn()
            printTitle("INFO", BadgeType.info, "Multiple rollback sources available for some files.")
            printLn()
            print("  Choose rollback source:")
            print("    \("1".cyan) - Backup files (.backup) - Restores files from last environment switch")
            print("    \("2".cyan) - Environment files (.\(currentEnvironment)) - Restores files from environment template")
            printLn()
            print("  Enter choice (1 or 2, default: \("1".dim))")
            print("  > ".cyan, terminator: "")

            let response = readLine() ?? ""
            let choice = response.trimmingCharacters(in: .whitespaces)

            rollbackSource = (choice == "2") ? "environment" : "backup"
        } else if !filesWithBackup.isEmpty {
            rollbackSource = "backup"
        } else {
            rollbackSource = "environment"
        }

        // Build list of files to rollback based on chosen source
        var filesToRollback: [String] = []
        var skippedFiles: [String] = []

        if rollbackSource == "backup" {
            filesToRollback = filesWithBackup + filesWithBoth
            skippedFiles = filesWithEnvironment
        } else {
            filesToRollback = filesWithEnvironment + filesWithBoth
            skippedFiles = filesWithBackup
        }

        if filesToRollback.isEmpty {
            printTitle("WARN", BadgeType.warning, "No files found for selected rollback source.")
            printLn()
            return
        }

        // Show what will be rolled back and ask for confirmation
        printLn()
        let sourceDescription = rollbackSource == "backup" ? "backup files (.backup)" : "environment files (.\(currentEnvironment))"
        printTitle("WARN", BadgeType.warning, "The following files will be restored from \(sourceDescription):")
        for file in filesToRollback {
            print("    \(file)".yellow)
        }

        printLn()
        print("  This will \("overwrite".bold.red) the current content of these files.")
        print("  Any changes you made will be \("lost".bold.red).")
        printLn()

        print("  Do you want to continue? (y/n, default: \("n".dim))")
        print("  > ".cyan, terminator: "")

        let confirmResponse = readLine() ?? ""
        let shouldContinue = confirmResponse.trimmingCharacters(in: .whitespaces).lowercased() == "y"

        guard shouldContinue else {
            printLn()
            printTitle("INFO", BadgeType.info, "Rollback cancelled.")
            printLn()
            return
        }

        printLn()
        printTitle("INFO", BadgeType.info, "Rolling back changes to environment files.")

        var rolledBackFiles: [String] = []
        var failedFiles: [String] = []

        for file in filesToRollback {
            let sourcePath = rollbackSource == "backup"
                ? "\(file).backup"
                : getFileEnvironmentPath(file: file, environment: currentEnvironment)
            let label = "\("Restoring file".dim) [\(sourcePath)] \("to".dim) [\(file)]"
            printUpdatableDotLine(label: label, value: "RUNNING".bold.dim)

            do {
                if fileManager.fileExists(atPath: file) {
                    try fileManager.removeItem(atPath: file)
                }

                try fileManager.copyItem(atPath: sourcePath, toPath: file)
                rolledBackFiles.append(file)
                printUpdatableDotLine(label: label, value: "DONE".bold.green, closeLine: true)
            } catch {
                failedFiles.append(file)
                printUpdatableDotLine(label: label, value: "FAILED".bold.red, closeLine: true)
            }
        }

        printLn()

        if !rolledBackFiles.isEmpty {
            printTitle("DONE", BadgeType.success, "Rolled back \(rolledBackFiles.count) file(s)")
            for file in rolledBackFiles {
                print("    \(file)".green)
            }
            printLn()
        }

        if !skippedFiles.isEmpty {
            let skippedSource = rollbackSource == "backup" ? "environment files" : "backup files"
            printTitle("INFO", BadgeType.info, "Skipped \(skippedFiles.count) file(s) (only \(skippedSource) available)")
            for file in skippedFiles {
                print("    \(file)".dim)
            }
            printLn()
        }

        if !filesWithNone.isEmpty {
            printTitle("WARN", BadgeType.warning, "No rollback sources found for \(filesWithNone.count) file(s)")
            for file in filesWithNone {
                print("    \(file)".dim)
            }
            printLn()
        }

        if !failedFiles.isEmpty {
            printTitle("ERROR", BadgeType.error, "Failed to rollback \(failedFiles.count) file(s)")
            for file in failedFiles {
                print("    \(file)".red)
            }
            printLn()
        }
    }
}
