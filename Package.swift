import PackageDescription

let package = Package(
    name: "t",
    dependencies: [
        .Package(url: "https://github.com/Baltoli/Cncurses.git", majorVersion: 1)
    ]
)
