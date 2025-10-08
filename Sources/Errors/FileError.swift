import Foundation

enum FileError: Error, LocalizedError {
    case inputFileNotFound
    
    var errorDescription: String? {
        switch self {
        case .inputFileNotFound:
            return "The input file does not exist!"
        }
    }
}
