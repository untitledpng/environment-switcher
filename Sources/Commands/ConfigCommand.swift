import Foundation

class ConfigCommand {
    func execute() throws {
        let configPath = GlobalConfig.globalConfigPath()

        // Check if global config already exists
        if FileManager.default.fileExists(atPath: configPath) {
            // Load existing config
            var config = GlobalConfig.load() ?? GlobalConfig()

            // Check if initDefaults already exist
            if config.initDefaults != nil {
                print(" ⏺ Global configuration already exists at:".yellow)
                print("   \(configPath)")
                print("\nTo view or edit the configuration, open this file in your editor.".dim)
                return
            }

            // Add initDefaults to existing config
            config.initDefaults = InitDefaults(
                environments: ["local", "staging", "production"],
                files: [".env"]
            )
            try config.save()

            print(" ⏺ Updated global configuration at:".green)
            print("   \(configPath)")
            print("\nAdded initDefaults configuration.".dim)
            return
        }

        // Create new global config with defaults
        let config = GlobalConfig(
            initDefaults: InitDefaults(
                environments: ["local", "staging", "production"],
                files: [".env"]
            )
        )
        try config.save()

        print(" ⏺ Created global configuration at:".green)
        print("   \(configPath)")
        print("\nThis file contains application-wide settings for the switch tool.".dim)
    }
}
