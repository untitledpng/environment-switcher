import ArgumentParser
import Foundation

struct SwitchCommand: ParsableCommand {
    @Argument(help: "Environment name (local, staging, production)")
    var environment: String
    var config: Config
    
    static let configuration = CommandConfiguration(
        commandName: "to",
        abstract: "Switch to environment",
        aliases: ["env"]
    )
    
    init() {
        self.config = ConfigService.shared.config
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
        
        let fileManager = FileManager.default
        
        for file in self.config.getFiles() {
            switchFile(fileManager: fileManager, inputFilePath: file, outputFilePath: "\(file).backup")
            switchFile(fileManager: fileManager, inputFilePath: getFileEnvironmentPath(file: file, environment: environment), outputFilePath: file)
        }
        
        updateEnvironment(newEnvironment: environment)
        
        printLn()
    }
    
    private func switchFile(fileManager: FileManager, inputFilePath: String, outputFilePath: String) {
        let label = "\("Copying file".dim) [\(inputFilePath)] \("to".dim) [\(outputFilePath)]"
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
}
