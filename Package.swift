// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GroktoDash",
    platforms: [.macOS(.v15)],  // SPM min; Xcode sets 26.0 deployment target
    products: [
        .library(name: "GroktoDashKit", targets: ["GroktoDashKit"]),
    ],
    targets: [
        // Framework — API client, models, auth (no UI imports)
        .target(
            name: "GroktoDashKit",
            path: "Sources/GroktoDashKit"
        ),
        // Tests for the framework
        .testTarget(
            name: "GroktoDashKitTests",
            dependencies: ["GroktoDashKit"],
            path: "Tests/GroktoDashKitTests"
        ),
        // App target — SwiftUI + App lifecycle (requires .xcodeproj to build)
        // Kept in Package.swift for source indexing; build via Xcode
        .target(
            name: "GroktoDash",
            dependencies: ["GroktoDashKit"],
            path: "Sources/GroktoDash"
        ),
        // Widget extension (requires .xcodeproj)
        .target(
            name: "GroktoDashWidgets",
            dependencies: ["GroktoDashKit"],
            path: "Sources/GroktoDashWidgets"
        ),
        // App Intents extension (requires .xcodeproj)
        .target(
            name: "GroktoDashIntents",
            dependencies: ["GroktoDashKit"],
            path: "Sources/GroktoDashIntents"
        ),
    ]
)
