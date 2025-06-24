// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Repository",
    platforms: [.iOS(.v17), .macOS(.v14), .macCatalyst(.v14), .tvOS(.v17), .watchOS(.v10), .visionOS(.v1)],
    products: [
        .library(name: "Repository", targets: ["Repository"])
    ],
    targets: [
        .target(
            name: "Repository"
            // swiftSettings: [.enableExperimentalFeature("NonisolatedNonsendingByDefault")]
        ),
        .testTarget(name: "RepositoryTests", dependencies: ["Repository"])
    ]
)
