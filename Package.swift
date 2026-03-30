// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ConfigPilot",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "ConfigPilot",
            path: "ConfigPilot",
            resources: [
                .copy("Resources/Schemas")
            ]
        ),
        .testTarget(
            name: "ConfigPilotTests",
            dependencies: ["ConfigPilot"],
            path: "ConfigPilotTests",
            resources: [
                .copy("Fixtures")
            ]
        ),
    ]
)
