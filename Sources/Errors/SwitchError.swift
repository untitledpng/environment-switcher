import Foundation

enum SwitchError: Error, LocalizedError {
    case configNotFound
    case configAlreadyExists
    case environmentNotFound(String)
    case invalidConfig
    case fileOperationFailed(String)
    case custom(String)

    var errorDescription: String? {
        switch self {
        case .configNotFound:
            return "No \(".switchrc".yellow) file found in current directory. Run '\("switch init".cyan)' to create one."
        case .configAlreadyExists:
            return "\(".switchrc".yellow) already exists in current directory"
        case .environmentNotFound(let env):
            return "Environment '\(env.cyan)' not found in .switchrc. Run '\("switch --list".cyan)' to see available environments."
        case .invalidConfig:
            return "Invalid \(".switchrc".yellow) format. Please check your JSON syntax."
        case .fileOperationFailed(let msg):
            return "File operation failed: \(msg)"
        case .custom(let msg):
            return msg
        }
    }
}
