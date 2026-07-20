// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "t",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "t"
        ),
        .testTarget(
            name: "t_tests",
            dependencies: ["t"]
        )
    ]
)
