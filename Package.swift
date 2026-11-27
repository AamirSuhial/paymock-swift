// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PayMock",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "PayMock",
            targets: ["PayMock"]
        ),
        .executable(
            name: "PayMockExample",
            targets: ["PayMockExample"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PayMock",
            dependencies: [],
            path: "Sources/PayMock"
        ),
        .executableTarget(
            name: "PayMockExample",
            dependencies: ["PayMock"],
            path: "Examples/PayMockExample/Sources"
        ),
        .testTarget(
            name: "PayMockTests",
            dependencies: ["PayMock"],
            path: "Tests/PayMockTests"
        )
    ]
)
