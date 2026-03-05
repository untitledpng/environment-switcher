import ArgumentParser
import Foundation

struct SwitchCommand: ParsableCommand {
    @Argument(help: "Environment name (local, staging, production)")
    var environment: String
    var config: Config
    var globalConfig: GlobalConfig
    
    static let configuration = CommandConfiguration(
        commandName: "to",
        abstract: "Switch to environment",
        aliases: ["env"]
    )
    
    init() {
        self.config = ConfigService.shared.config
        self.globalConfig = GlobalConfigService.shared.config
    }

    mutating func run() throws {        
        if self.config.current_environment == environment {
            printTitle("WARN", BadgeType.warning, "The \(environment) environment is already active.")
            print("  Use \("switch rollback".cyan) if you want to rollback your changes made in the active environment files.")
            printLn()
            return
        }
        
        if self.config.getFiles().isEmpty {
            printTitle("ERROR", BadgeType.error, "No files configured for this environment.")
            printLn()
            return
        }
        
        printTitle("INFO", BadgeType.info, "Switching to the \(environment) environment.")

        if shouldShowExtendAlphaWarning() {
            printTitle("WARN", BadgeType.warning, "ALPHA: Extend mode is experimental and may produce invalid files in edge cases.")
        }
        
        let fileManager = FileManager.default
        
        for file in self.config.getFiles() {
            switchFile(fileManager: fileManager, inputFilePath: file, outputFilePath: "\(file).backup", operation: "backup")
            switchFileWithMode(fileManager: fileManager, file: file)
        }
        
        updateEnvironment(newEnvironment: environment)
        runPostSwitchCommands()
        
        printLn()
    }
    
    private func switchFile(fileManager: FileManager, inputFilePath: String, outputFilePath: String, operation: String) {
        let label = "\("Copying file (\(operation))".dim) [\(inputFilePath)] \("to".dim) [\(outputFilePath)]"
        printUpdatableDotLine(label: label, value: "RUNNING".bold.dim)
        
        do {
            guard fileManager.fileExists(atPath: inputFilePath) else {
                throw FileError.inputFileNotFound
            }
            
            if fileManager.fileExists(atPath: outputFilePath) {
                try fileManager.removeItem(atPath: outputFilePath)
            }
            
            try fileManager.copyItem(atPath: inputFilePath, toPath: outputFilePath)
        } catch {
            printUpdatableDotLine(label: label, value: "FAILED".bold.red, closeLine: true)
            return
        }
        
        printUpdatableDotLine(label: label, value: "DONE".bold.green, closeLine: true)
    }

    private func switchFileWithMode(fileManager: FileManager, file: String) {
        let mode = resolveFileSwitchMode(file: file, config: self.config, globalConfig: self.globalConfig)
        let sourcePath = getFileEnvironmentPath(file: file, environment: environment)
        let label = "\("Applying \(mode.rawValue) strategy".dim) [\(sourcePath)] \("to".dim) [\(file)]"
        printUpdatableDotLine(label: label, value: "RUNNING".bold.dim)

        do {
            _ = try applySwitchForFile(
                fileManager: fileManager,
                file: file,
                environment: environment,
                config: self.config,
                globalConfig: self.globalConfig
            )
        } catch {
            printUpdatableDotLine(label: label, value: "FAILED".bold.red, closeLine: true)
            return
        }

        printUpdatableDotLine(label: label, value: "DONE".bold.green, closeLine: true)
    }
    
    private mutating func updateEnvironment(newEnvironment: String) {
        let label = "\("Updating configuration file".dim) [.switchrc]"
        printUpdatableDotLine(label: label, value: "RUNNING".bold.dim)
        
        self.config.current_environment = newEnvironment
        
        do {
            try self.config.save()
        } catch {
            print("\r\u{001B}[K", terminator: "")
            printUpdatableDotLine(label: label, value: "FAILED".bold.red, closeLine: true)
            return
        }
        
        printUpdatableDotLine(label: label, value: "DONE".bold.green, closeLine: true)
    }

    private func runPostSwitchCommands() {
        guard let commands = self.config.environments[environment]?.post_switch, !commands.isEmpty else {
            return
        }

        printTitle("INFO", BadgeType.info, "Running post-switch commands")

        for command in commands {
            let label = "\("Executing".dim) [\(command)]"
            printUpdatableDotLine(label: label, value: "RUNNING".bold.dim)

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-c", command]
            process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

            do {
                try process.run()
                process.waitUntilExit()

                if process.terminationStatus != 0 {
                    printUpdatableDotLine(label: label, value: "FAILED".bold.red, closeLine: true)
                    continue
                }
            } catch {
                printUpdatableDotLine(label: label, value: "FAILED".bold.red, closeLine: true)
                continue
            }

            printUpdatableDotLine(label: label, value: "DONE".bold.green, closeLine: true)
        }
    }

    private func shouldShowExtendAlphaWarning() -> Bool {
        for file in self.config.getFiles() {
            let mode = resolveFileSwitchMode(file: file, config: self.config, globalConfig: self.globalConfig)
            let isWhitelisted = isFileWhitelistedForExtend(file: file, whitelist: self.config.effectiveExtendWhitelist(globalConfig: self.globalConfig))
            let hasHandler = resolveExtendHandler(file: file) != nil

            if mode == .extend && self.config.isExtendEnabled(globalConfig: self.globalConfig) && isWhitelisted && hasHandler {
                return true
            }
        }

        return false
    }
}
