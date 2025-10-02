import Foundation

class ShowCommand {
    let fm = FileManager.default
    let currentDir = FileManager.default.currentDirectoryPath

    func execute() throws {
        let config = try loadConfig()

        print("Current environment: ".bold, terminator: "")

        if let currentEnv = config.currentEnvironment {
            if config.environments[currentEnv] != nil {
                let files = config.getFiles(for: currentEnv)
                let (matchedFiles, modifiedFiles) = try checkEnvironmentFiles(currentEnv, files)

                if modifiedFiles.isEmpty {
                    print(currentEnv.cyan.bold)
                } else {
                    print("\(currentEnv.yellow.bold) (modified)".yellow)
                }

                for file in matchedFiles {
                    print("  ⎿  \(file)")
                }
                for file in modifiedFiles {
                    print("  ⎿  \("\(file) (modified)".brightYellow)")
                }
            } else {
                print("\(currentEnv.red.bold) (not found in config)".red)
            }
        } else {
            print("none".dim)
        }

        print("\nAvailable environments:".bold)

        if let files = config.files {
            print("Default files: \(files.joined(separator: ", ").dim)\n")
        }

        for (name, _) in config.environments.sorted(by: { $0.key < $1.key }) {
            let files = config.getFiles(for: name)
            print(" • \(name.cyan.bold)")
            print("  ⎿  Files: \(files.joined(separator: ", ").dim)")
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

    private func checkEnvironmentFiles(_ envName: String, _ files: [String]) throws -> ([String], [String]) {
        var matchedFiles: [String] = []
        var modifiedFiles: [String] = []

        for filePath in files {
            let fullPath = "\(currentDir)/\(filePath)"
            let envPath = "\(fullPath).\(envName)"

            guard fm.fileExists(atPath: fullPath), fm.fileExists(atPath: envPath) else {
                continue
            }

            if try filesAreIdentical(fullPath, envPath) {
                matchedFiles.append(filePath)
            } else {
                modifiedFiles.append(filePath)
            }
        }

        return (matchedFiles, modifiedFiles)
    }

    private func filesAreIdentical(_ path1: String, _ path2: String) throws -> Bool {
        let data1 = try Data(contentsOf: URL(fileURLWithPath: path1))
        let data2 = try Data(contentsOf: URL(fileURLWithPath: path2))
        return data1 == data2
    }

}
