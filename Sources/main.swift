import Foundation

// For Swift Package Manager, code at top level is executed automatically
// No need to wrap in a function or call main()

let args = CommandLine.arguments

if args.count < 2 {
    let showCommand = ShowCommand()
    do {
        try showCommand.execute()
    } catch {
        print(" ⏺ Failed to detect current environment...".red)
    }
    exit(1)
}

let command = args[1]

do {
    if command == "--list" || command == "-l" {
        let listCommand = ListCommand()
        try listCommand.execute()
    } else if command == "--help" || command == "-h" {
        let helpCommand = HelpCommand()
        helpCommand.execute()
    } else if command == "init" {
        let initCommand = InitCommand()
        try initCommand.execute()
    } else {
        let switchCommand = SwitchCommand()
        try switchCommand.execute(environment: command)
    }
} catch {
    print("Error: ".red + error.localizedDescription)
    exit(1)
}
