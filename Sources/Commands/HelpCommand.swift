import Foundation

class HelpCommand {
    func execute() {
        print("\nAvailable arguments:".bold)
        print("""
        Usage: switch <environment>
               switch --list
               switch --help
               switch init

        Examples:
               switch init
               switch --list
               switch --help
               switch production
               switch development
        """)
    }
}
