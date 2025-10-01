import Foundation

// For Swift Package Manager, code at top level is executed automatically
// No need to wrap in a function or call main()

let args = CommandLine.arguments
let switcher = EnvironmentSwitcher()

if args.count < 2 {
    print("""
    Usage: switch <environment>
           switch --list
    
    Examples:
      switch production
      switch development
      switch --list
    """)
    exit(1)
}

let command = args[1]

do {
    if command == "--list" || command == "-l" {
        try switcher.listEnvironments()
    } else {
        try switcher.switchEnvironment(to: command)
    }
} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}
