// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TrackWorkoutCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "TrackWorkoutCore",
            targets: ["TrackWorkoutCore"]
        )
    ],
    targets: [
        .target(
            name: "TrackWorkoutCore"
        ),
        .testTarget(
            name: "TrackWorkoutCoreTests",
            dependencies: ["TrackWorkoutCore"]
        )
    ]
)
