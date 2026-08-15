// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SitStandTimer",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "SitStandTimer", targets: ["SitStandTimer"]),
        .executable(name: "TimerModelTests", targets: ["TimerModelTests"]),
        .library(name: "SitStandTimerCore", targets: ["SitStandTimerCore"]),
    ],
    targets: [
        .target(
            name: "SitStandTimerCore"
        ),
        .executableTarget(
            name: "SitStandTimer",
            dependencies: ["SitStandTimerCore"]
        ),
        .executableTarget(
            name: "TimerModelTests",
            dependencies: ["SitStandTimerCore"],
            path: "Tests/SitStandTimerTests"
        ),
    ]
)
