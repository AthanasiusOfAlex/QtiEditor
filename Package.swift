// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "QtiEditor",
    platforms: [.macOS(.v15)],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "QtiEditor",
            dependencies: []
        )
    ]
)
