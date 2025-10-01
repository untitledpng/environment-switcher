// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "environment-switcher",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(
            name: "switch",
            targets: ["EnvironmentSwitcher"])
    ],
    targets: [
        .executableTarget(
            name: "EnvironmentSwitcher",
            path: "Sources")
    ]
)
