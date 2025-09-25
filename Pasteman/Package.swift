// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Pasteman",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Pasteman",
            targets: ["Pasteman"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Pasteman",
            dependencies: [],
            path: "Sources"
        )
    ]
)