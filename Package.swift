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
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.1"),
        .package(url: "https://github.com/onevcat/Rainbow", .upToNextMajor(from: "4.0.0")),
    ],
    targets: [
        .executableTarget(
            name: "EnvironmentSwitcher",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Rainbow", package: "Rainbow")
            ],
            path: "Sources")
    ]
)
