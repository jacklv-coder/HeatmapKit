// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HeatmapKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "HeatmapKit",
            targets: ["HeatmapKit"]
        ),
        .executable(
            name: "HeatmapKitDemo",
            targets: ["HeatmapKitDemo"]
        ),
    ],
    targets: [
        .target(
            name: "HeatmapKit"
        ),
        .executableTarget(
            name: "HeatmapKitDemo",
            dependencies: ["HeatmapKit"],
            path: "Demo"
        ),
        .testTarget(
            name: "HeatmapKitTests",
            dependencies: ["HeatmapKit"]
        ),
    ]
)
