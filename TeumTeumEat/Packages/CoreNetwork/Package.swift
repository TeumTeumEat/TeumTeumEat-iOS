// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CoreNetwork",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "CoreNetwork",
            targets: ["CoreNetwork"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.23.1"),
    ],
    targets: [
        .target(
            name: "CoreNetwork",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Sources/CoreNetwork",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
