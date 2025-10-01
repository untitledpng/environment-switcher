import Foundation

// For Swift Package Manager, code at top level is executed automatically
// No need to wrap in a function or call main()

let args = CommandLine.arguments
let switcher = EnvironmentSwitcher()

if args.count < 2 {
    print("""
    Usage: switch <environment>
           switch --list
           switch init

    Examples:
      switch init
      switch --list
      switch production
      switch development
    """)
    exit(1)
}

let command = args[1]

do {
    if command == "--list" || command == "-l" {
        try switcher.listEnvironments()
    } else if command == "init" {
        try switcher.initializeConfig()
    } else {
        try switcher.switchEnvironment(to: command)
    }
} catch {
    print("Error: ".red + error.localizedDescription)
    exit(1)
}
