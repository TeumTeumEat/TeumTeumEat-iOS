//
//  DateFormattersTests.swift
//  TeumTeumEatTests
//

import Foundation
import Testing
@testable import TeumTeumEat

struct DateFormattersTests {
    @Test("서버 날짜 문자열을 한국어 월/일로 표시한다")
    func serverDate_toKoreanMonthDay() throws {
        let date = try #require(DateFormatters.yearMonthDay.date(from: "2026-10-05"))
        #expect(DateFormatters.yearMonthDay.string(from: date) == "2026-10-05")
        #expect(DateFormatters.koreanMonthDay.string(from: date) == "10월 5일")
        #expect(DateFormatters.koreanMonth.string(from: date) == "10월")
        #expect(DateFormatters.monthDotDay.string(from: date) == "10.05")
    }

    @Test("서버 일시(마이크로초 포함)를 파싱한다")
    func serverDateTime_parses() throws {
        let date = try #require(DateFormatters.serverDateTime.date(from: "2026-10-05T09:30:00.123456"))
        #expect(DateFormatters.yearMonthDay.string(from: date) == "2026-10-05")
    }

    @Test("ISO 8601(소수 초 포함) 문자열을 파싱한다")
    func iso8601_parses() {
        #expect(DateFormatters.iso8601WithFractionalSeconds.date(from: "2026-10-05T09:30:00.123Z") != nil)
        #expect(DateFormatters.iso8601WithFractionalSeconds.date(from: "2026-10-05") == nil)
    }
}
