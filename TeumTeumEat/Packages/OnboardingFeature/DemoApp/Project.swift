import ProjectDescription

let project = Project(
    name: "OnboardingDemoApp",
    packages: [
        .local(path: ".."),
    ],
    targets: [
        .target(
            name: "OnboardingDemoApp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.teumteumeat.OnboardingDemoApp",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchStoryboardName": "",
                "CFBundleDisplayName": "Onboarding Demo",
            ]),
            sources: ["Sources/**"],
            dependencies: [
                .package(product: "OnboardingFeature"),
            ]
        ),
    ]
)
