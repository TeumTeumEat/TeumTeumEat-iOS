//
//  QuizFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct HistoryFeature {
    @ObservableState
    struct State: Equatable {
        var fireCount: Int = 0
        var stampCount: Int = 0
        // 탭 관련 상태
        var selectedTab: Int = 0
        let tabs: [TTETabItem] = [
            TTETabItem(title: "날짜별"),
            TTETabItem(title: "주제별")
        ]
        
        var calendarData: CalendarHistoryData?
        var currentYear: Int = Calendar.current.component(.year, from: Date())
        var currentMonth: Int = Calendar.current.component(.month, from: Date())
    }
    
    enum Action {
        case onAppear
        case settingTapped
        case tabSelected(Int)
        case monthChanged(year: Int, month: Int)
        case calendarDataLoaded(Result<CalendarHistoryData, Error>)
        case delegate(Delegate)
    }
    
    enum Delegate {
        case openMyPageRequested
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
         Reduce { state, action in
             switch action {
             case .onAppear:
                 return .run { [year = state.currentYear, month = state.currentMonth] send in
                     await send(.monthChanged(year: year, month: month))
                 }
                 
             case .settingTapped:
                 return .send(.delegate(.openMyPageRequested))
                 
             case .tabSelected(let index):
                 state.selectedTab = index
                 return .none
                 
             case .monthChanged(let year, let month):
                 state.currentYear = year
                 state.currentMonth = month
                 
                 return .run { send in
                     await send(.calendarDataLoaded(
                         Result {
                             try await apiClient.fetchCalendarHistory(year: year, month: month)
                         }
                     ))
                 }
                 
             case .calendarDataLoaded(.success(let data)):
                 state.calendarData = data
                 // stampCount를 totalStamps로 업데이트
                 state.stampCount = data.totalStamps
                 print("Calendar data loaded: \(data.stampedDates.count) stamped dates, total: \(data.totalStamps)")
                 return .none
                 
             case .calendarDataLoaded(.failure(let error)):
                 print("    Failed to load calendar data: \(error)")
                 return .none
                 
             case .delegate:
                 return .none
             }
         }
     }
 }

struct HistoryView: View {
    let store: StoreOf<HistoryFeature>
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 네비게이션 바 - 최상단 고정
                HomeNavigationBar(
                    fireCount: store.fireCount,
                    stampCount: store.stampCount,
                    onSettingTapped: {
                        store.send(.settingTapped)
                    }
                )
                
                // 나머지 전체 스크롤
                ScrollView {
                    VStack(spacing: 0) {
                        // 탭 헤더
                        TTETabHeader(
                            selectedTab: Binding(
                                get: { store.selectedTab },
                                set: { store.send(.tabSelected($0)) }
                            ),
                            tabs: store.tabs
                        )
                        .padding(.top, 1)
                        
                        VStack(spacing: 16) {
                            switch store.selectedTab {
                            case 0:
                                // 날짜별
                                VStack(spacing: 16) {
                                    HistoryDateCard(
                                        fireCount: store.fireCount,
                                        dateText: "얼른 시작 틈틈잇",
                                        characterImage: "Frame 7407"
                                    )
                                    
                                    // 스탬프 카운트 HStack
                                    HStack(spacing: 12) {
                                        StampCountCapsule(
                                            title: "총 스탬프",
                                            count: store.calendarData?.totalStamps ?? 0,
                                            iconName: "stamp",
                                            backgroundColor: Color(hex: "EAF4FF")
                                        )
                                        
                                        StampCountCapsule(
                                            title: "이번달 스탬프",
                                            count: store.calendarData?.stampedDates.count ?? 0,
                                            iconName: "stamp",
                                            backgroundColor: Color(hex: "EAF4FF")
                                        )
                                    }
                                    
                                    HistoryCalendarView(
                                        currentYear: store.currentYear,
                                        currentMonth: store.currentMonth,
                                        stampedDates: store.calendarData?.stampedDates ?? [],
                                        onMonthChanged: { year, month in
                                            store.send(.monthChanged(year: year, month: month))
                                        }
                                    )
                                    .padding(.top, 5)
                                }
                                .padding(.horizontal, 18)
                                .padding(.top, 20)
                                .padding(.bottom, 120)
                                
                            case 1:
                                // 주제별
                                VStack(spacing: 16) {
                                    ExpandableSummaryRow(
                                        categories: ["앱 개발자", "Swift", "SwiftUI"],
                                        items: [
                                            QuizHistoryItem(
                                                id: "1",
                                                title: "SwiftUI 레이아웃 기초",
                                                dateText: "1월 2일 목요일",
                                                isStreak: true
                                            ),
                                            QuizHistoryItem(
                                                id: "2",
                                                title: "State와 Binding 이해하기",
                                                dateText: "1월 1일 수요일",
                                                isStreak: true
                                            ),
                                            QuizHistoryItem(
                                                id: "3",
                                                title: "View Modifier 활용",
                                                dateText: "12월 30일 월요일",
                                                isStreak: false
                                            )
                                        ],
                                        onItemTapped: { item in
                                            print("선택된 항목: \(item.title)")
                                        }
                                    )
                                    
                                    ExpandableSummaryRow(
                                        categories: ["앱 개발자", "iOS", "UIKit"],
                                        items: [
                                            QuizHistoryItem(
                                                id: "4",
                                                title: "UIViewController 생명주기",
                                                dateText: "12월 28일 토요일",
                                                isStreak: false
                                            )
                                        ],
                                        onItemTapped: { item in
                                            print("선택된 항목: \(item.title)")
                                        }
                                    )
                                    
                                    ExpandableSummaryRow(
                                        categories: ["CS", "알고리즘", "정렬"],
                                        items: [
                                            QuizHistoryItem(
                                                id: "5",
                                                title: "퀵소트 구현하기",
                                                dateText: "12월 25일 수요일",
                                                isStreak: false
                                            )
                                        ],
                                        onItemTapped: { item in
                                            print("선택된 항목: \(item.title)")
                                        }
                                    )
                                }
                                .padding(.horizontal, 18)
                                .padding(.top, 20)
                                .padding(.bottom, 120)
                                
                            default:
                                EmptyView()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarHidden(true)
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}



struct HistoryDateCard: View {
    let fireCount: Int
    let dateText: String
    let characterImage: String
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 8) {
                // 왼쪽 영역 - 남은 공간 차지
                VStack(alignment: .trailing, spacing: 0) {
                    HStack(spacing: 8) {
                        Image("fire")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(.orange)
                            .frame(width: 50, height: 50)
                       
                        
                        Text("\(fireCount)")
                            .font(.system(size: 40, weight: .regular))
                            .foregroundColor(.black)
                    }
                    .frame(height: 66)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    Text(dateText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(height: 42)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: .infinity)
                .background(Color(hex: "EAF4FF"))
                
                // 오른쪽 영역 - 카드 절반 크기
                Image(characterImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width / 2)
                    .frame(height: 188)
                    .clipped()
            }
        }
        .frame(height: 188)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "EAF4FF"))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct StampCountCapsule: View {
    let title: String
    let count: Int
    let iconName: String
    let backgroundColor: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
            
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            
            Text("\(count)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            Capsule()
                .fill(backgroundColor)
        )
    }
}

struct HistoryCalendarView: View {
    let currentYear: Int
    let currentMonth: Int
    let stampedDates: [String]
    let onMonthChanged: (Int, Int) -> Void
    
    @State private var selectedDate: Date?
    
    let calendar = Calendar.current
    
    // stampedDates를 Date 배열로 변환
    private var quizDates: [Date] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return stampedDates.compactMap { formatter.date(from: $0) }
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
            if let selectedDate = selectedDate {
                selectedDateInfo(date: selectedDate)
                    .padding(.top, 16)
            }
        }
    }
    
    // MARK: - 월 헤더
    private var monthHeader: some View {
        HStack(spacing: 12) {
            Button(action: {
                let newMonth = currentMonth == 1 ? 12 : currentMonth - 1
                let newYear = currentMonth == 1 ? currentYear - 1 : currentYear
                onMonthChanged(newYear, newMonth)
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            Text(monthYearString)
                .font(.system(size: 18, weight: .bold))
            
            Button(action: {
                let newMonth = currentMonth == 12 ? 1 : currentMonth + 1
                let newYear = currentMonth == 12 ? currentYear + 1 : currentYear
                onMonthChanged(newYear, newMonth)
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
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
                    let hasQuiz = quizDates.contains(where: {
                        calendar.isDate($0, inSameDayAs: date)
                    })
                    
                    DayCell(
                        date: date,
                        isSelected: selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!),
                        hasQuiz: hasQuiz,
                        isStreak: false // TODO: 연속 달성 로직 추가 필요 시
                    )
                    .onTapGesture {
                        if hasQuiz {
                            selectedDate = date
                        }
                    }
                    .disabled(!hasQuiz)
                } else {
                    Color.clear
                        .frame(height: 40)
                }
            }
        }
    }
    
    // MARK: - 선택된 날짜 정보
    private func selectedDateInfo(date: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dateString(date))
                .font(.system(size: 16, weight: .bold))
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                    Text("퀴즈 완료")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            // TODO: 실제 퀴즈 데이터 표시
            Text("완료한 퀴즈: 확인 필요")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "EAF4FF"))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: currentMonthDate)
    }
    
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: date)
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
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasQuiz: Bool // 퀴즈 완료한 날
    let isStreak: Bool // 연속 퀴즈
    
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            // 배경 (선택 시)
            if isSelected {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
            }
            
            // 날짜 텍스트
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 14, weight: hasQuiz ? .bold : .regular))
                .foregroundColor(hasQuiz ? .black : .gray)
            
            // 퀴즈 완료 표시 (동그라미)
            if hasQuiz {
                Circle()
                    .stroke(isStreak ? Color.orange : Color.blue, lineWidth: 2)
                    .frame(width: 36, height: 36)
            }
        }
        .frame(height: 40)
    }
}
