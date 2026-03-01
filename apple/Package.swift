// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Mentat",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        .library(
            name: "MentatShared",
            targets: ["MentatShared"]
        ),
    ],
    targets: [
        .target(
            name: "MentatShared",
            path: "Shared"
        ),
        .testTarget(
            name: "MentatSharedTests",
            dependencies: ["MentatShared"]
        ),
    ]
)
