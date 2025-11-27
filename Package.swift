// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QtiEditor",
    platforms: [
        .macOS(.v15)  // For @Observable and modern SwiftUI features
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "QtiEditor",
            dependencies: [],
            path: "Sources/QtiEditor"
        ),
    ],
)
