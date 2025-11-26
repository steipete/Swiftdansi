// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftMarkdown: Target.Dependency = .product(
    name: "Markdown",
    package: "swift-markdown"
)

let displayWidth: Target.Dependency = .product(
    name: "DisplayWidth",
    package: "swift-displaywidth"
)

let argumentParser: Target.Dependency = .product(
    name: "ArgumentParser",
    package: "swift-argument-parser"
)

let package = Package(
    name: "Swiftdansi",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2),
    ],
    products: [
        .library(
            name: "Swiftdansi",
            targets: ["Swiftdansi"]
        ),
        .executable(
            name: "swiftdansi",
            targets: ["SwiftdansiCLIMain"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown", from: "0.7.0"),
        .package(url: "https://github.com/ainame/swift-displaywidth", from: "0.0.3"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.4.0"),
    ],
    targets: [
        .target(
            name: "Swiftdansi",
            dependencies: [
                swiftMarkdown,
                displayWidth,
            ]
        ),
        .target(
            name: "SwiftdansiCLI",
            dependencies: [
                "Swiftdansi",
                argumentParser,
            ]
        ),
        .executableTarget(
            name: "SwiftdansiCLIMain",
            dependencies: [
                "SwiftdansiCLI"
            ]
        ),
        .testTarget(
            name: "SwiftdansiTests",
            dependencies: ["Swiftdansi", "SwiftdansiCLI"],
            path: "Tests/SwiftdansiTests"
        ),
    ]
)
