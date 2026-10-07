//
//  DateFormatters.swift
//  TeumTeumEat
//

import Foundation

/// 여러 화면에서 쓰는 날짜 포맷터 (생성 비용이 커서 한 번만 만들어 재사용)
///
/// 서버와 주고받는 고정 형식은 en_US_POSIX + 그레고리력으로 고정해
/// 기기 달력 설정이 불교력 / 일본력이어도 "2026-10-05"가 다른 연도로 바뀌지 않도록 함
enum DateFormatters {
    /// "2026-10-05" (서버 날짜)
    static let yearMonthDay = fixed("yyyy-MM-dd")
    /// "2026-10-05T12:34:56.123456" (서버 일시, 타임존 없음)
    static let serverDateTime = fixed("yyyy-MM-dd'T'HH:mm:ss.SSSSSS")
    /// "2026-10-05T12:34:56.123Z" (ISO 8601, 소수 초 포함)
    static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// "10.05"
    static let monthDotDay = fixed("MM.dd")
    /// "10월"
    static let koreanMonth = korean("M월")
    /// "10월 5일"
    static let koreanMonthDay = korean("M월 d일")

    private static func fixed(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = format
        return formatter
    }

    private static func korean(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = format
        return formatter
    }
}
