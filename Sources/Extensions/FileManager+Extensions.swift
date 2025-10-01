import Foundation

extension FileManager {
    func fileExists(atPath path: String) -> Bool {
        var isDir: ObjCBool = false
        let exists = fileExists(atPath: path, isDirectory: &isDir)
        return exists && !isDir.boolValue
    }
}
