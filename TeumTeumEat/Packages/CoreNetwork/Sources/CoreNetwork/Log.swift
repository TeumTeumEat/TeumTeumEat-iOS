//
//  Log.swift
//  TeumTeumEat
//

import OSLog

/// 앱 공통 로거 (os.Logger 래퍼)
///
/// - Xcode 콘솔에서 subsystem `com.TeumTeumEat` 또는 category(Network, Home 등)로 필터링하면
///   시스템/광고 SDK 로그 없이 앱 로그만 볼 수 있음
/// - `debug`는 Debug 빌드에서만 기록 (Release에서는 메시지 문자열 생성도 하지 않음)
/// - Release 빌드의 `error` 메시지는 private 처리되어 기기 로그(Console.app)에서 가려짐
public struct Log: Sendable {
    public static let app = Log(category: "App")
    public static let auth = Log(category: "Auth")
    public static let network = Log(category: "Network")
    public static let home = Log(category: "Home")
    public static let quiz = Log(category: "Quiz")
    public static let history = Log(category: "History")
    public static let myPage = Log(category: "MyPage")
    public static let register = Log(category: "Register")
    public static let onboarding = Log(category: "Onboarding")
    public static let ad = Log(category: "Ad")

    private static let subsystem = "com.TeumTeumEat"

    private let logger: Logger

    private init(category: String) {
        self.logger = Logger(subsystem: Self.subsystem, category: category)
    }

    public func debug(_ message: @autoclosure () -> String) {
        #if DEBUG
        let message = message()
        logger.debug("\(message, privacy: .public)")
        #endif
    }

    public func error(_ message: @autoclosure () -> String) {
        let message = message()
        #if DEBUG
        logger.error("\(message, privacy: .public)")
        #else
        logger.error("\(message, privacy: .private)")
        #endif
    }
}
