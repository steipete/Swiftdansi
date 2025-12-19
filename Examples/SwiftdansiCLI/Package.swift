// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftdansiDemo",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "SwiftdansiDemo",
            dependencies: [
                .product(name: "Swiftdansi", package: "Swiftdansi"),
            ]),
        .testTarget(
            name: "SwiftdansiDemoTests",
            dependencies: [
                .product(name: "Swiftdansi", package: "Swiftdansi"),
            ]),
    ])
