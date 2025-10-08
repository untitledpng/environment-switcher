import ArgumentParser

struct ConfigCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Create your global config file to edit default values."
    )
    
    func run() throws {
        // TODO: Add --force support to override the existing global config with the default values.
        if GlobalConfigService.configExists() {
            printTitle("WARN", BadgeType.warning, "The global config has already been created.")
            print("\("You can modify the file at".dim) [\(GlobalConfigService.configPath)]\(".".dim)")
            printLn()
            return
        }
        
        let globalConfig = GlobalConfigService.shared.config
        let label = "\("Creating global config file".dim) [\(GlobalConfigService.configPath)]"
        
        printTitle("INFO", BadgeType.info, "Creating global config file")
        printUpdatableDotLine(label: label, value: "RUNNING".bold.dim)
        
        do {
            try globalConfig.save()
        } catch {
            printUpdatableDotLine(label: label, value: "FAILED".bold.red, closeLine: true)
            print("Error: \(error.localizedDescription)")
            return
        }
        
        printUpdatableDotLine(label: label, value: "DONE".bold.green, closeLine: true)
        print("Global configuration file created successfully. You can now edit the default values by editing the file mentioned above.")
        
        printLn()
    }
}
