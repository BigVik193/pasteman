// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PastePal",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "PastePal",
            targets: ["PastePal"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "PastePal",
            dependencies: [],
            path: "Sources"
        )
    ]
)