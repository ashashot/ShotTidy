// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ShotTidyMac",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ShotTidyMac",
            path: "Sources/ShotTidyMac",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        )
    ]
)
