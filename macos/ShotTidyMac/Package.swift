// swift-tools-version: 6.0
import PackageDescription

// Target: macOS 15 (Sequoia) minimum — fully compatible with macOS 26 (Tahoe).
// To build for macOS 26+ exclusively, change .macOS(.v15) to .macOS(.v26)
// once the macOS 26 SDK is available in your Xcode installation.

let package = Package(
    name: "ShotTidyMac",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "ShotTidyMac",
            path: "Sources/ShotTidyMac",
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        )
    ]
)
