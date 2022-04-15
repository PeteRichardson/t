// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "t",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "t", targets: ["t"]),
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(
            name: "t",
            dependencies: []),
    ]
)
