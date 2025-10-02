import Foundation

// For Swift Package Manager, code at top level is executed automatically
// No need to wrap in a function or call main()

let args = CommandLine.arguments

if args.count < 2 {
    let configPath = "\(FileManager.default.currentDirectoryPath)/.switchrc"

    if !FileManager.default.fileExists(atPath: configPath) {
        print(" ⏺ No .switchrc file found in current directory".red)
        print("\nTo get started, run:".bold)
        print("  \("switch init".cyan) - Create a new .switchrc configuration file")
        exit(1)
    }

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
    } else if command == "config" {
        let configCommand = ConfigCommand()
        try configCommand.execute()
    } else if command == "add" {
        let addCommand = AddCommand()
        try addCommand.execute()
    } else if command == "remove" || command == "rm" {
        let removeCommand = RemoveCommand()
        try removeCommand.execute()
    } else {
        let switchCommand = SwitchCommand()
        try switchCommand.execute(environment: command)
    }
} catch {
    print("Error: ".red + error.localizedDescription)
    exit(1)
}
