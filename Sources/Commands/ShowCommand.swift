import Foundation

class ShowCommand {
    let fm = FileManager.default
    let currentDir = FileManager.default.currentDirectoryPath

    enum EnvironmentStatus {
        case matched(String, [String])
        case modified(String, [String], [String])
        case unknown
    }

    func execute() throws {
        let config = try loadConfig()
        let current = try detectCurrentEnvironment(config: config)

        print("Current environment: ".bold, terminator: "")

        switch current {
        case .matched(let envName, let allFiles):
            print(envName.cyan.bold)
            for file in allFiles {
                print("  ⎿  \(file)")
            }
        case .modified(let envName, let matchedFiles, let modifiedFiles):
            print("\(envName.yellow.bold) (modified)".yellow)
            for file in matchedFiles {
                print("  ⎿  \(file)")
            }
            for file in modifiedFiles {
                print("  ⎿  \("\(file) (modified)".brightYellow)")
            }
        case .unknown:
            print("unknown".dim)
        }

        print("\nAvailable environments:".bold)
        for (name, envConfig) in config.environments.sorted(by: { $0.key < $1.key }) {
            print(" • \(name.cyan.bold)")
            print("  ⎿  Files: \(envConfig.files.joined(separator: ", ").dim)")
        }
    }

    // MARK: - Private Methods

    private func loadConfig() throws -> SwitchConfig {
        let configPath = "\(currentDir)/.switchrc"

        guard fm.fileExists(atPath: configPath) else {
            throw SwitchError.configNotFound
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
        let decoder = JSONDecoder()

        do {
            return try decoder.decode(SwitchConfig.self, from: data)
        } catch {
            throw SwitchError.invalidConfig
        }
    }

    private func detectCurrentEnvironment(config: SwitchConfig) throws -> EnvironmentStatus {
        var bestMatch: (name: String, matchCount: Int, totalFiles: Int, matchedFiles: [String], modifiedFiles: [String]) = ("", 0, 0, [], [])

        for (envName, envConfig) in config.environments {
            var matchCount = 0
            var matchedFiles: [String] = []
            var modifiedFiles: [String] = []
            let totalFiles = envConfig.files.count

            for filePath in envConfig.files {
                let fullPath = "\(currentDir)/\(filePath)"
                let envPath = "\(fullPath).\(envName)"

                guard fm.fileExists(atPath: fullPath), fm.fileExists(atPath: envPath) else {
                    continue
                }

                if try filesAreIdentical(fullPath, envPath) {
                    matchCount += 1
                    matchedFiles.append(filePath)
                } else {
                    modifiedFiles.append(filePath)
                }
            }

            if matchCount > bestMatch.matchCount {
                bestMatch = (envName, matchCount, totalFiles, matchedFiles, modifiedFiles)
            }
        }

        if bestMatch.matchCount == 0 {
            return .unknown
        } else if bestMatch.matchCount == bestMatch.totalFiles {
            return .matched(bestMatch.name, bestMatch.matchedFiles)
        } else {
            return .modified(bestMatch.name, bestMatch.matchedFiles, bestMatch.modifiedFiles)
        }
    }

    private func filesAreIdentical(_ path1: String, _ path2: String) throws -> Bool {
        let data1 = try Data(contentsOf: URL(fileURLWithPath: path1))
        let data2 = try Data(contentsOf: URL(fileURLWithPath: path2))
        return data1 == data2
    }
}
