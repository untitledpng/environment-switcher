import Foundation

class HelpCommand {
    func execute() {
        print("\nAvailable arguments:".bold)
        print("""
        Usage: switch <environment>
               switch --list
               switch --help
               switch init
               switch config

        Commands:
               init                 Create a new .switchrc configuration file in current directory
               config               Create or view global configuration file
               --list, -l           List all available environments
               --help, -h           Show this help message
               <environment>        Switch to the specified environment

        Examples:
               switch init          Initialize a new project
               switch config        Setup global configuration
               switch --list        List environments
               switch production    Switch to production environment
        """)
    }
}
