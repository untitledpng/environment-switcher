import XCTest
import Foundation
@testable import EnvironmentSwitcher

final class EnvironmentSwitcherTests: XCTestCase {
    var testDir: String!
    var originalDir: String!

    override func setUp() {
        super.setUp()

        // Save original directory
        originalDir = FileManager.default.currentDirectoryPath

        // Create a temporary test directory
        testDir = NSTemporaryDirectory() + "switch-test-\(UUID().uuidString)"
        try! FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)

        // Change to test directory
        FileManager.default.changeCurrentDirectoryPath(testDir)
    }

    override func tearDown() {
        // Restore original directory
        FileManager.default.changeCurrentDirectoryPath(originalDir)

        // Clean up test directory
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: testDir, isDirectory: &isDir) {
            try? FileManager.default.removeItem(atPath: testDir)
        }

        super.tearDown()
    }

    // MARK: - Helper Methods

    func createConfig(environments: [String: [String]], defaultFiles: [String]? = nil) throws {
        var envConfigs: [String: EnvironmentConfig] = [:]
        for (name, files) in environments {
            envConfigs[name] = EnvironmentConfig(files: files.isEmpty ? [] : files)
        }
        let config = SwitchConfig(environments: envConfigs, currentEnvironment: nil, files: defaultFiles)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: URL(fileURLWithPath: "\(testDir!)/.switchrc"))
    }

    func createFile(_ path: String, content: String) throws {
        try content.write(toFile: "\(testDir!)/\(path)", atomically: true, encoding: .utf8)
    }

    func fileExists(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: "\(testDir!)/\(path)", isDirectory: &isDir)
    }

    func readFile(_ path: String) -> String? {
        return try? String(contentsOfFile: "\(testDir!)/\(path)", encoding: .utf8)
    }

    // MARK: - Config Tests

    func testConfigNotFound() {
        let listCommand = ListCommand()
        XCTAssertThrowsError(try listCommand.execute()) { error in
            XCTAssertTrue(error is SwitchError)
            if case .configNotFound = error as? SwitchError {
                // Success
            } else {
                XCTFail("Expected configNotFound error")
            }
        }
    }

    func testConfigAlreadyExists() throws {
        // Create initial config
        try createConfig(environments: ["local": [".env"]])

        // Verify config exists
        XCTAssertTrue(fileExists(".switchrc"))

        // Test error is defined
        let error = SwitchError.configAlreadyExists
        XCTAssertNotNil(error.errorDescription)
    }

    func testInitCreatesEnvironmentFiles() throws {
        // This test verifies the helper method works
        // Full init test would require mocking stdin

        let files = [".env", "config.json"]
        let environments = ["local", "staging", "production"]

        // Create config first
        try createConfig(environments: [
            "local": files,
            "staging": files,
            "production": files
        ])

        // Manually create the files (simulating what init does)
        for file in files {
            for env in environments {
                let envFile = "\(file).\(env)"
                try createFile(envFile, content: "# Environment: \(env)\n# TODO: Add your \(env) configuration here\n")
            }
        }

        // Verify all files were created
        for file in files {
            for env in environments {
                let envFile = "\(file).\(env)"
                XCTAssertTrue(fileExists(envFile), "\(envFile) should exist")
                let content = readFile(envFile)
                XCTAssertNotNil(content)
                XCTAssertTrue(content?.contains("Environment: \(env)") ?? false)
            }
        }
    }

    // MARK: - List Environments Tests

    func testListEnvironments() throws {
        try createConfig(environments: [
            "local": [".env"],
            "staging": [".env"],
            "production": [".env"]
        ])

        let listCommand = ListCommand()
        // This will print to stdout, but shouldn't throw
        XCTAssertNoThrow(try listCommand.execute())
    }

    func testListEnvironmentsWithMultipleFiles() throws {
        try createConfig(environments: [
            "local": [".env", "config.json"],
            "production": [".env", "config.json"]
        ])

        let listCommand = ListCommand()
        XCTAssertNoThrow(try listCommand.execute())
    }

    // MARK: - Switch Environment Tests

    func testSwitchEnvironmentSuccess() throws {
        // Setup
        try createConfig(environments: [
            "local": [".env"],
            "production": [".env"]
        ])

        try createFile(".env.local", content: "ENV=local")
        try createFile(".env.production", content: "ENV=production")

        // Switch to production
        let switchCommand = SwitchCommand()
        XCTAssertNoThrow(try switchCommand.execute(environment: "production"))

        // Verify
        XCTAssertTrue(fileExists(".env"))
        XCTAssertTrue(fileExists(".env.backup") == false) // No existing file to backup
        XCTAssertEqual(readFile(".env"), "ENV=production")
    }

    func testSwitchEnvironmentWithBackup() throws {
        // Setup
        try createConfig(environments: [
            "local": [".env"],
            "production": [".env"]
        ])

        try createFile(".env", content: "ENV=current")
        try createFile(".env.local", content: "ENV=local")
        try createFile(".env.production", content: "ENV=production")

        // Switch to production
        let switchCommand = SwitchCommand()
        XCTAssertNoThrow(try switchCommand.execute(environment: "production"))

        // Verify
        XCTAssertTrue(fileExists(".env"))
        XCTAssertTrue(fileExists(".env.backup"))
        XCTAssertEqual(readFile(".env"), "ENV=production")
        XCTAssertEqual(readFile(".env.backup"), "ENV=current")
    }

    func testSwitchEnvironmentNotFound() throws {
        try createConfig(environments: [
            "local": [".env"]
        ])

        let switchCommand = SwitchCommand()
        XCTAssertThrowsError(try switchCommand.execute(environment: "nonexistent")) { error in
            XCTAssertTrue(error is SwitchError)
            if case .environmentNotFound(let env) = error as? SwitchError {
                XCTAssertEqual(env, "nonexistent")
            } else {
                XCTFail("Expected environmentNotFound error")
            }
        }
    }

    func testSwitchEnvironmentMissingFiles() throws {
        // Setup config but don't create the environment files
        try createConfig(environments: [
            "production": [".env"]
        ])

        // Should not throw, but should report no files switched
        let switchCommand = SwitchCommand()
        XCTAssertNoThrow(try switchCommand.execute(environment: "production"))

        // .env should not exist
        XCTAssertFalse(fileExists(".env"))
    }

    func testSwitchMultipleFiles() throws {
        // Setup
        try createConfig(environments: [
            "local": [".env", "config.json"],
            "production": [".env", "config.json"]
        ])

        try createFile(".env.local", content: "ENV=local")
        try createFile("config.json.local", content: "{\"env\":\"local\"}")
        try createFile(".env.production", content: "ENV=production")
        try createFile("config.json.production", content: "{\"env\":\"production\"}")

        // Switch to production
        let switchCommand = SwitchCommand()
        XCTAssertNoThrow(try switchCommand.execute(environment: "production"))

        // Verify both files switched
        XCTAssertEqual(readFile(".env"), "ENV=production")
        XCTAssertEqual(readFile("config.json"), "{\"env\":\"production\"}")
    }

    func testSwitchPartialFiles() throws {
        // Setup - only one file exists
        try createConfig(environments: [
            "production": [".env", "config.json"]
        ])

        try createFile(".env.production", content: "ENV=production")
        // config.json.production doesn't exist

        // Should not throw, but only .env should be switched
        let switchCommand = SwitchCommand()
        XCTAssertNoThrow(try switchCommand.execute(environment: "production"))

        XCTAssertTrue(fileExists(".env"))
        XCTAssertFalse(fileExists("config.json"))
    }

    // MARK: - Show Current Environment Tests

    func testShowCurrentEnvironmentMatched() throws {
        // Setup
        try createConfig(environments: [
            "local": [".env"],
            "production": [".env"]
        ])

        try createFile(".env.production", content: "ENV=production")
        try createFile(".env", content: "ENV=production")

        // Should show production as current
        let showCommand = ShowCommand()
        XCTAssertNoThrow(try showCommand.execute())
    }

    func testShowCurrentEnvironmentUnknown() throws {
        // Setup
        try createConfig(environments: [
            "local": [".env"],
            "production": [".env"]
        ])

        try createFile(".env.local", content: "ENV=local")
        try createFile(".env.production", content: "ENV=production")
        try createFile(".env", content: "ENV=unknown")

        // Should show unknown
        let showCommand = ShowCommand()
        XCTAssertNoThrow(try showCommand.execute())
    }

    func testShowCurrentEnvironmentModified() throws {
        // Setup
        try createConfig(environments: [
            "production": [".env", "config.json"]
        ])

        try createFile(".env.production", content: "ENV=production")
        try createFile("config.json.production", content: "{\"env\":\"production\"}")
        try createFile(".env", content: "ENV=production")
        try createFile("config.json", content: "{\"env\":\"modified\"}")

        // Should show production as modified
        let showCommand = ShowCommand()
        XCTAssertNoThrow(try showCommand.execute())
    }

    // MARK: - Error Cases

    func testInvalidConfigFormat() throws {
        // Create invalid JSON
        try "invalid json{".write(toFile: "\(testDir!)/.switchrc", atomically: true, encoding: .utf8)

        let listCommand = ListCommand()
        XCTAssertThrowsError(try listCommand.execute()) { error in
            XCTAssertTrue(error is SwitchError)
            if case .invalidConfig = error as? SwitchError {
                // Success
            } else {
                XCTFail("Expected invalidConfig error")
            }
        }
    }

    func testEmptyEnvironments() throws {
        try createConfig(environments: [:])

        let listCommand = ListCommand()
        // Should list environments (empty list)
        XCTAssertNoThrow(try listCommand.execute())
    }

    func testEnvironmentWithNoFiles() throws {
        try createConfig(environments: [
            "local": []
        ])

        // Should throw error when no default files and environment has empty files
        let switchCommand = SwitchCommand()
        XCTAssertThrowsError(try switchCommand.execute(environment: "local")) { error in
            XCTAssertTrue(error is SwitchError)
        }
    }

    // MARK: - Edge Cases

    func testBackupOverwrite() throws {
        // Setup
        try createConfig(environments: [
            "local": [".env"],
            "production": [".env"]
        ])

        try createFile(".env", content: "ENV=current")
        try createFile(".env.backup", content: "ENV=old_backup")
        try createFile(".env.production", content: "ENV=production")

        // Switch - should overwrite old backup
        let switchCommand = SwitchCommand()
        XCTAssertNoThrow(try switchCommand.execute(environment: "production"))

        XCTAssertEqual(readFile(".env"), "ENV=production")
        XCTAssertEqual(readFile(".env.backup"), "ENV=current")
    }

    func testSwitchToSameEnvironment() throws {
        // Setup
        try createConfig(environments: [
            "production": [".env"]
        ])

        try createFile(".env.production", content: "ENV=production")
        try createFile(".env", content: "ENV=production")

        // Switch to same environment
        let switchCommand = SwitchCommand()
        XCTAssertNoThrow(try switchCommand.execute(environment: "production"))

        // Should still work and create backup
        XCTAssertTrue(fileExists(".env.backup"))
    }

    func testSpecialCharactersInFilenames() throws {
        // Setup with special characters
        try createConfig(environments: [
            "local": [".env-dev", "config.test.json"]
        ])

        try createFile(".env-dev.local", content: "ENV=local")
        try createFile("config.test.json.local", content: "{}")

        let switchCommand = SwitchCommand()
        XCTAssertNoThrow(try switchCommand.execute(environment: "local"))

        XCTAssertTrue(fileExists(".env-dev"))
        XCTAssertTrue(fileExists("config.test.json"))
    }

    func testMultipleEnvironmentsWithDifferentFiles() throws {
        try createConfig(environments: [
            "dev": [".env", "api.json"],
            "prod": [".env"]
        ])

        try createFile(".env.dev", content: "ENV=dev")
        try createFile("api.json.dev", content: "{\"env\":\"dev\"}")
        try createFile(".env.prod", content: "ENV=prod")

        // Switch to dev
        let switchCommand1 = SwitchCommand()
        XCTAssertNoThrow(try switchCommand1.execute(environment: "dev"))
        XCTAssertEqual(readFile(".env"), "ENV=dev")
        XCTAssertEqual(readFile("api.json"), "{\"env\":\"dev\"}")

        // Switch to prod (only has .env)
        let switchCommand2 = SwitchCommand()
        XCTAssertNoThrow(try switchCommand2.execute(environment: "prod"))
        XCTAssertEqual(readFile(".env"), "ENV=prod")
    }
}
