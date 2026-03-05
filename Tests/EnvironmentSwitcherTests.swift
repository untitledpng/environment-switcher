import XCTest
@testable import EnvironmentSwitcher

final class EnvironmentSwitcherTests: XCTestCase {
    func testMergeDotenvOverridesKeysFromEnvironmentFile() {
        let base = """
        APP_URL=example.foo
        APP_ENV=local
        KEEP_ME=true
        """

        let env = """
        APP_URL=helloworld.test
        APP_ENV=production
        """

        let merged = mergeDotenv(defaultContent: base, environmentContent: env)

        XCTAssertTrue(merged.contains("APP_URL=helloworld.test"))
        XCTAssertTrue(merged.contains("APP_ENV=production"))
        XCTAssertTrue(merged.contains("KEEP_ME=true"))
        XCTAssertFalse(merged.contains("APP_URL=example.foo"))
    }

    func testRecursiveMergePhpValueOverridesNestedValues() {
        let base: [String: Any] = [
            "db": [
                "connection": [
                    "default": [
                        "host": "localhost",
                        "dbname": "magento"
                    ]
                ]
            ]
        ]

        let env: [String: Any] = [
            "db": [
                "connection": [
                    "default": [
                        "host": "db.internal"
                    ]
                ]
            ]
        ]

        let merged = recursiveMergePhpValue(base, env) as? [String: Any]
        let db = merged?["db"] as? [String: Any]
        let connection = db?["connection"] as? [String: Any]
        let `default` = connection?["default"] as? [String: Any]

        XCTAssertEqual(`default`?["host"] as? String, "db.internal")
        XCTAssertEqual(`default`?["dbname"] as? String, "magento")
    }

    func testResolveModePrefersProjectFileOverrideThenGlobalFileThenProjectModeThenGlobalMode() {
        let global = makeGlobalConfig(
            mode: "replace",
            fileModes: [".env": "replace", "env.php": "extend"]
        )

        let config = Config(
            current_environment: "local",
            environments: ["local": Environment(files: [])],
            default_files: [".env", "env.php"],
            mode: "extend",
            extend_enabled: true,
            extend_whitelist: [".env", "env.php"],
            file_modes: [".env": "extend"]
        )

        XCTAssertEqual(config.effectiveMode(for: ".env", globalConfig: global), "extend")
        XCTAssertEqual(config.effectiveMode(for: "env.php", globalConfig: global), "extend")
        XCTAssertEqual(config.effectiveMode(for: "config.json", globalConfig: global), "extend")
    }

    func testProjectExtendEnabledAndWhitelistOverrideGlobal() {
        let global = makeGlobalConfig(
            mode: "replace",
            extendEnabled: false,
            whitelist: [".env"]
        )

        let config = Config(
            current_environment: "local",
            environments: ["local": Environment(files: [])],
            default_files: [".env"],
            mode: nil,
            extend_enabled: true,
            extend_whitelist: ["env.php"],
            file_modes: nil
        )

        XCTAssertTrue(config.isExtendEnabled(globalConfig: global))
        XCTAssertEqual(config.effectiveExtendWhitelist(globalConfig: global), ["env.php"])
    }

    func testUnsupportedFileTypeFallsBackToReplaceByHandlerResolution() {
        XCTAssertNil(resolveExtendHandler(file: "config.json"))
        XCTAssertNotNil(resolveExtendHandler(file: ".env"))
        XCTAssertNotNil(resolveExtendHandler(file: "app/etc/env.php"))
    }

    private func makeGlobalConfig(
        mode: String,
        extendEnabled: Bool = false,
        whitelist: [String] = [],
        fileModes: [String: String] = [:]
    ) -> GlobalConfig {
        var config = GlobalConfig()
        config.mode = mode
        config.extend_enabled = extendEnabled
        config.extend_whitelist = whitelist
        config.file_modes = fileModes
        return config
    }
}
