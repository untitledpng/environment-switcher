import Foundation
import Rainbow

enum ConfigError: Error, LocalizedError {
    case configNotFound
    case configAlreadyExists
    case invalidConfig
    
    var errorDescription: String? {
        switch self {
        case .configNotFound:
            return "No \(".switchrc".yellow) file found in current directory. Run '\("switch init".cyan)' to create one."
        case .configAlreadyExists:
            return "\(".switchrc".yellow) already exists in current directory"
        case .invalidConfig:
            return "Invalid \(".switchrc".yellow) format. Please check your JSON syntax."
        }
    }
}
