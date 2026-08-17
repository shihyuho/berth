// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Berth",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Berth",
            path: "Sources/Berth"
        )
    ]
)
