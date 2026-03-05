import Foundation

enum FileError: Error, LocalizedError {
    case inputFileNotFound
    case extendBaseFileNotFound
    case invalidPhpArrayFile
    case phpExecutionFailed(message: String)
    
    var errorDescription: String? {
        switch self {
        case .inputFileNotFound:
            return "The input file does not exist!"
        case .extendBaseFileNotFound:
            return "The .default file is required when using extend mode."
        case .invalidPhpArrayFile:
            return "The PHP file must return an associative array."
        case .phpExecutionFailed(let message):
            return "Could not parse PHP file: \(message)"
        }
    }
}
