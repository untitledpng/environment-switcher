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
    }
    
    private func askEnvironments() throws -> [String] {
        printLn()
        print("Which environments do you want to add?")
        print("(comma-separated, default: \(self.globalConfig.default_environments.joined(separator: ",").dim))")
        print("> ".cyan, terminator: "")
        
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
        print("Which files should be switched?")
        print("(comma-separated, default: \(self.globalConfig.default_files.joined(separator: ",").dim))")
        print("> ".cyan, terminator: "")

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
}
