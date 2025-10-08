import ArgumentParser

struct StatusCommand: ParsableCommand {
    let config: Config
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "View the current state of the application"
    )
    
    init() {
        self.config = ConfigService.shared.config
    }
    
    func run() throws {
        printLn()
        printDotLine(label: "Environment".bold.green)
        printDotLine(label: "Current environment", value: self.config.current_environment.uppercased().green)
        printDotLine(label: "Available environments", value: self.config.environments.keys.joined(separator: ",").dim)
        
        printLn()
        printDotLine(label: "Environment files".bold.green)
        for file in self.config.getFiles() {
            let fileStatus = getFileStatus(file: file, environment: self.config.current_environment)
            var path = file

            if fileStatus == FileStatus.modified {
                path += " (modified)"
            }
            
            if fileStatus == FileStatus.notFound {
                path += " (not found)"
            }

            printDotLine(
                value: path
                    .colorIf(fileStatus == FileStatus.modified, .yellow)
                    .colorIf(fileStatus == FileStatus.notFound, .red)
                    .styleIf(fileStatus == FileStatus.original, .dim)
            )
        }
        
        printLn()
        printDotLine(label: "Configuration".bold.green)
        printDotLine(label: "Default files", value: self.config.default_files.joined(separator: ",").dim)
        
        printLn()
    }
}
