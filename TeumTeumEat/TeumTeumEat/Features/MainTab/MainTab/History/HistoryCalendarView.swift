//
//  HistoryCalendarView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture
import OnboardingFeature

struct HistoryCalendarView: View {
    let currentYear: Int
    let currentMonth: Int
    let stampedDates: [String] // "2026-01-04" 형식
    let selectedDateString: String? // 선택된 날짜 문자열
    let historyItems: [HistoryItemResponse] // 선택된 날짜의 히스토리 아이템
    let onMonthChanged: (Int, Int) -> Void
    let onDateSelected: (String?) -> Void // 날짜 선택/해제 콜백
    let onItemTapped: (Int, String, String) -> Void
    
    let calendar = Calendar.current
    
    // stampedDates를 Date 배열로 변환
    private var quizDates: [Date] {
        stampedDates.compactMap { DateFormatters.yearMonthDay.date(from: $0) }
    }
    
    private var currentMonthDate: Date {
        let components = DateComponents(year: currentYear, month: currentMonth)
        return calendar.date(from: components) ?? Date()
    }
    
    var body: some View {
        VStack(spacing: 8) {
            monthHeader
            weekdayHeader
                .padding(.top, 8)
            calendarGrid
            
            // 선택된 날짜 정보
            if selectedDateString != nil, !historyItems.isEmpty {
                selectedDateInfo()
                    .padding(.top, 0)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedDateString)
    }
    
    // MARK: - 월 헤더
    private var monthHeader: some View {
        HStack(spacing: 24) {
            Button(action: {
                let newMonth = currentMonth == 1 ? 12 : currentMonth - 1
                let newYear = currentMonth == 1 ? currentYear - 1 : currentYear
                onMonthChanged(newYear, newMonth)
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray800)
            }

            Text(monthYearString)
                .stSemibold18()
                .foregroundStyle(.gray900)

            Button(action: {
                let newMonth = currentMonth == 12 ? 1 : currentMonth + 1
                let newYear = currentMonth == 12 ? currentYear + 1 : currentYear
                onMonthChanged(newYear, newMonth)
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray800)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 요일 헤더
    private var weekdayHeader: some View {
        let daysOfWeek = ["월", "화", "수", "목", "금", "토", "일"]
        
        return HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - 달력 그리드
    private var calendarGrid: some View {
        let days = getDaysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                if let date = date {
                    dayCell(for: date)
                } else {
                    Color.clear
                        .frame(height: 40)
                }
            }
        }
    }
    
    private func dayCell(for date: Date) -> some View {
        let dateString = dateToString(date)
        let hasQuiz = stampedDates.contains(dateString)
        
        return DayCell(
            date: date,
            isSelected: selectedDateString == dateString,
            hasQuiz: hasQuiz,
            isStreak: false // TODO: 연속 달성 로직 추가 필요 시
        )
        .onTapGesture {
            if hasQuiz {
                // 토글 방식
                if selectedDateString == dateString {
                    onDateSelected(nil) // 선택 해제
                } else {
                    onDateSelected(dateString) // 선택
                }
            }
        }
        .disabled(!hasQuiz)
    }
    
    // MARK: - 선택된 날짜 정보
    private func selectedDateInfo() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 제목 (테두리 밖)
            Text("이날 공부한 내용")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
            
            // 히스토리 아이템들
            VStack(spacing: 12) {
                ForEach(historyItems, id: \.id) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        // 제목과 날짜
                        HStack {
                            Text(item.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Text(formatDate(item.lastStudiedAt))
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        // 요약 내용
                        Text(item.summarySnippet)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "EAF4FF"))
                    .cornerRadius(12)
                    .onTapGesture {  
                        onItemTapped(item.id, item.type, extractDateOnly(item.lastStudiedAt))
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private var monthYearString: String {
        DateFormatters.koreanMonth.string(from: currentMonthDate)
    }
    
    private func dateToString(_ date: Date) -> String {
        DateFormatters.yearMonthDay.string(from: date)
    }
    
    private func formatDate(_ dateString: String) -> String {
        if let date = DateFormatters.serverDateTime.date(from: dateString) {
            return DateFormatters.koreanMonthDay.string(from: date)
        }
        
        // 파싱 실패 시 앞부분만 잘라서 표시
        if dateString.count >= 10 {
            let dateOnly = String(dateString.prefix(10)) // "2026-01-04"
            if let date = DateFormatters.yearMonthDay.date(from: dateOnly) {
                return DateFormatters.koreanMonthDay.string(from: date)
            }
        }
        
        return dateString
    }
    
    private func getDaysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonthDate) else {
            return []
        }
        
        let monthFirstDay = monthInterval.start
        let weekday = calendar.component(.weekday, from: monthFirstDay)
        let emptyDays = (weekday + 5) % 7
        
        var days: [Date?] = Array(repeating: nil, count: emptyDays)
        
        let range = calendar.range(of: .day, in: .month, for: currentMonthDate)!
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthFirstDay) {
                days.append(date)
            }
        }
        
        while days.count < 42 {
            days.append(nil)
        }
        
        return days
    }
    
    private func extractDateOnly(_ dateString: String) -> String {
        // "2026-01-04T10:30:00.123456" -> "2026-01-04"
        if dateString.count >= 10 {
            return String(dateString.prefix(10))
        }
        return dateString
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasQuiz: Bool // 퀴즈 완료한 날
    let isStreak: Bool // 연속 퀴즈
    
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            // 퀴즈 완료 날짜 배경 (채워진 원)
            if hasQuiz {
                Circle()
                    .fill(isSelected ? Color.blue500 : Color.blue300)
                    .frame(width: 28, height: 28)
            }
            
            // 날짜 텍스트
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 14, weight: hasQuiz ? .bold : .regular))
                .foregroundColor(hasQuiz ? .white : .gray)
        }
        .frame(height: 40)
    }
}
