// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Berth",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "BerthCore",
            path: "Sources/BerthCore"
        ),
        .executableTarget(
            name: "Berth",
            dependencies: ["BerthCore"],
            path: "Sources/Berth"
        ),
        .testTarget(
            name: "BerthCoreTests",
            dependencies: ["BerthCore"],
            path: "Tests/BerthCoreTests"
        ),
        .testTarget(
            name: "BerthAppTests",
            dependencies: ["Berth"],
            path: "Tests/BerthAppTests"
        )
    ]
)
