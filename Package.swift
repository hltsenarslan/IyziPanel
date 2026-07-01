// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IyziPanel",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "IyziPanel",
            path: "Sources/IyziPanel",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
