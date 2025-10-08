import Foundation
import ArgumentParser

let _ = ConfigService.shared
let _ = GlobalConfigService.shared

struct EnvironmentSwitcher: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "switch",
        abstract: "A utility for managing files",
        subcommands: [
            StatusCommand.self,
            InitCommand.self,
            ConfigCommand.self,
            SwitchCommand.self,
        ],
        defaultSubcommand: StatusCommand.self
    )
}

do {
    var command = try EnvironmentSwitcher.parseAsRoot()
    try command.run()
} catch {
    let args = Array(CommandLine.arguments.dropFirst())
    if let environmentName = args.first, !environmentName.starts(with: "-") {
        if nil != ConfigService.shared.config.environments[environmentName] {
            var toCommand = SwitchCommand()
            toCommand.environment = environmentName

            try? toCommand.run()
            exit(0)
        }
    }

    EnvironmentSwitcher.exit(withError: error)
}
