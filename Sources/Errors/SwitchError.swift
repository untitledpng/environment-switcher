import Foundation

enum SwitchError: Error, LocalizedError {
    case configNotFound
    case environmentNotFound(String)
    case invalidConfig
    case fileOperationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .configNotFound:
            return "No .switchrc file found in current directory"
        case .environmentNotFound(let env):
            return "Environment '\(env)' not found in .switchrc"
        case .invalidConfig:
            return "Invalid .switchrc format"
        case .fileOperationFailed(let msg):
            return "File operation failed: \(msg)"
        }
    }
}
