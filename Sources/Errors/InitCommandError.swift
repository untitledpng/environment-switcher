import Foundation

enum InitCommandError: Error, LocalizedError {
    case noEnvironmentsProvided
    case noFilesProvided
    
    var errorDescription: String? {
        switch self {
            case .noEnvironmentsProvided:
                return "No environments specified!"
            case .noFilesProvided:
                return "No files specified!"
        }
    }
}
