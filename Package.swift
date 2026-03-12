// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Lightning",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.1")
    ],
    targets: [
        .executableTarget(
            name: "Lightning",
            dependencies: ["HotKey"],
            path: "Sources/Lightning",
            resources: [
                .copy("../Resources/Info.plist")
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/Resources/Info.plist"
                ])
            ]
        ),
        .testTarget(
            name: "LightningTests",
            dependencies: ["Lightning"],
            path: "Tests/LightningTests"
        )
    ]
)
