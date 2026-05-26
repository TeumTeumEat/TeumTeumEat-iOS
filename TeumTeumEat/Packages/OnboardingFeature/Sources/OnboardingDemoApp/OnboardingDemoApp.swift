import SwiftUI
import OnboardingFeature
import ComposableArchitecture

@main
struct OnboardingDemoApp: App {
    var body: some Scene {
        WindowGroup {
            OnboardingView(
                store: Store(initialState: OnboardingFeature.State()) {
                    OnboardingFeature()
                } withDependencies: {
                    $0.onboardingAPIClient = .testValue
                    $0.categoryAPIClient = .testValue
                }
            )
        }
    }
}
