// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "RobotChess",
    platforms: [
        .iOS(.v11),
    ],
    targets: [
        .target(name: "RobotChess", path: "RobotChess"),
    ]
)
