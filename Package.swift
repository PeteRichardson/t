// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "t",
    dependencies: [
    ],
    targets: [
        .systemLibrary(name: "ncurses", path:"Sources/ncurses"),
        .target(
            name: "t",
            dependencies: ["ncurses"],
            linkerSettings: [.linkedLibrary("ncurses", .when(platforms: [.linux, .macOS]))]
        ),
    ]
)

// Note that to build you have to pass Xlinker options to swift build to get the ncurses
// library to link with the tool.    See below.
// There must be a way of specifying this explicitly in this file, 
// but linkerSettings on the .systemLibrary call doesn't seem to work.
//
//    swift build -v -Xlinker -L/usr/local/Cellar/ncurses/6.1/lib/ -Xlinker -lncurses