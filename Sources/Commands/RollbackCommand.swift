import ArgumentParser
import Foundation

struct RollbackCommand: ParsableCommand {
    var config: Config

    static let configuration = CommandConfiguration(
        commandName: "rollback",
        abstract: "Rollback changes to environment files by restoring from backup"
    )

    init() {
        self.config = ConfigService.shared.config
    }

    func run() throws {
        let fileManager = FileManager.default
        let files = self.config.getFiles()

        if files.isEmpty {
            printTitle("ERROR", BadgeType.error, "No files configured for this environment.")
            printLn()
            return
        }

        // Check if backup files exist
        var backupFiles: [String] = []
        var missingBackups: [String] = []

        for file in files {
            let backupPath = "\(file).backup"
            if fileManager.fileExists(atPath: backupPath) {
                backupFiles.append(file)
            } else {
                missingBackups.append(file)
            }
        }

        if backupFiles.isEmpty {
            printTitle("WARN", BadgeType.warning, "No backup files found to rollback.")
            print("  Backup files are created when you switch environments.")
            printLn()
            return
        }

        // Show what will be rolled back and ask for confirmation
        printLn()
        printTitle("WARN", BadgeType.warning, "The following files will be restored from backup:")
        for file in backupFiles {
            print("    \(file)".yellow)
        }

        printLn()
        print("  This will \("overwrite".bold.red) the current content of these files with their backup versions.")
        print("  Any changes you made since the last environment switch will be \("lost".bold.red).")
        printLn()

        print("  Do you want to continue? (y/n, default: \("n".dim))")
        print("  > ".cyan, terminator: "")

        let response = readLine() ?? ""
        let shouldContinue = response.trimmingCharacters(in: .whitespaces).lowercased() == "y"

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

        for file in backupFiles {
            let backupPath = "\(file).backup"
            let label = "\("Restoring file".dim) [\(backupPath)] \("to".dim) [\(file)]"
            printUpdatableDotLine(label: label, value: "RUNNING".bold.dim)

            do {
                if fileManager.fileExists(atPath: file) {
                    try fileManager.removeItem(atPath: file)
                }

                try fileManager.copyItem(atPath: backupPath, toPath: file)
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

        if !missingBackups.isEmpty {
            printTitle("WARN", BadgeType.warning, "No backups found for \(missingBackups.count) file(s)")
            for file in missingBackups {
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
