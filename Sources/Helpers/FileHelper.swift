import CryptoKit
import Foundation

func sha256(filePath: String) -> String? {
    guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
        return nil
    }
    
    let hash = SHA256.hash(data: fileData)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
}

func getFileStatus(file: String, environment: String) -> FileStatus {
    if let activeEnvironmentFileHash = sha256(filePath: file) {
        if let originalEnvironmentFileHash = sha256(filePath: getFileEnvironmentPath(file: file, environment: environment)) {
            if activeEnvironmentFileHash == originalEnvironmentFileHash {
                return FileStatus.original
            }
            return FileStatus.modified
        }
    }

    return FileStatus.notFound
}

func getFileEnvironmentPath(file: String, environment: String) -> String {
    return "\(file).\(environment)"
}
