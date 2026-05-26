// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OnboardingFeature",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "OnboardingFeature",
            targets: ["OnboardingFeature"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.23.1"),
        .package(url: "https://github.com/airbnb/lottie-ios", from: "4.5.2"),
        .package(path: "../DesignSystem"),
        .package(path: "../CoreNetwork"),
    ],
    targets: [
        .target(
            name: "OnboardingFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Lottie", package: "lottie-ios"),
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "CoreNetwork", package: "CoreNetwork"),
            ],
            path: "Sources/OnboardingFeature",
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
