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
        var myPage: MyPageFeature.State?
        
        // 탭 관련 상태
        var selectedTab: Int = 0
        let tabs: [TTETabItem] = [
            TTETabItem(title: "날짜별"),
            TTETabItem(title: "주제별")
        ]
    }
    
    enum Action {
        case settingTapped
        case myPage(MyPageFeature.Action)
        case tabSelected(Int)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .settingTapped:
                state.myPage = MyPageFeature.State()
                return .none
                
            case .tabSelected(let index):
                state.selectedTab = index
                return .none
                
            case .myPage(.delegate(.dismissed)):
                state.myPage = nil
                return .none
                
            case .myPage:
                return .none
            }
        }
        .ifLet(\.myPage, action: \.myPage) {
            MyPageFeature()
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
                // .padding(.horizontal, 20) <- 제거
                
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
                                        fireCount: 5,
                                        dateText: "얼른 시작 틈틈잇",
                                        characterImage: "Frame 7407"
                                    )
                                    
                                    // 스탬프 카운트 HStack
                                    HStack(spacing: 12) {
                                        StampCountCapsule(
                                            title: "총 스탬프",
                                            count: store.stampCount,
                                            iconName: "stamp",
                                            backgroundColor: Color(hex: "EAF4FF")
                                        )
                                        
                                        StampCountCapsule(
                                            title: "이번달 스탬프",
                                            count: store.stampCount,
                                            iconName: "stamp",
                                            backgroundColor: Color(hex: "EAF4FF")
                                        )
                                    }
                                    
                                    HistoryCalendarView(
                                        quizDates: [
                                            Date(),
                                            Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                                            Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                                            Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
                                        ],
                                        streakDates: [
                                            Date(),
                                            Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                                            Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                                        ]
                                    )
                                    .padding(.top, 5)
                                }
                                .padding(.horizontal, 18) // 전체에 padding 적용
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
            .navigationDestination(
                isPresented: Binding(
                    get: { store.myPage != nil },
                    set: { if !$0 { store.send(.myPage(.delegate(.dismissed))) } }
                )
            ) {
                if let myPageStore = store.scope(state: \.myPage, action: \.myPage) {
                    MyPageView(store: myPageStore)
                }
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
    @State private var currentMonth = Date()
    @State private var selectedDate: Date?
    
    let calendar = Calendar.current
    
    let quizDates: [Date]
    let streakDates: [Date]
    
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
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            Text(monthYearString)
                .font(.system(size: 18, weight: .bold))
            
            Button(action: { changeMonth(by: 1) }) {
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
                    let isStreak = streakDates.contains(where: {
                        calendar.isDate($0, inSameDayAs: date)
                    })
                    
                    DayCell(
                        date: date,
                        isSelected: selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!),
                        hasQuiz: hasQuiz,
                        isStreak: isStreak
                    )
                    .onTapGesture {
                        // 퀴즈가 있는 날짜만 선택 가능
                        if hasQuiz {
                            selectedDate = date
                        }
                    }
                    .disabled(!hasQuiz) // 퀴즈 없는 날짜는 비활성화
                } else {
                    Color.clear
                        .frame(height: 40)
                }
            }
        }
    }
    
    // MARK: - 선택된 날짜 정보
    private func selectedDateInfo(date: Date) -> some View {
        let isStreak = streakDates.contains(where: {
            calendar.isDate($0, inSameDayAs: date)
        })
        
        return VStack(alignment: .leading, spacing: 12) {
            Text(dateString(date))
                .font(.system(size: 16, weight: .bold))
            
            HStack(spacing: 16) {
                // 퀴즈 완료 정보
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                    Text("퀴즈 완료")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                // 스트릭 정보
                if isStreak {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("연속 달성")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // TODO: 실제 퀴즈 데이터 표시
            Text("완료한 퀴즈: 5개")
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
        return formatter.string(from: currentMonth)
    }
    
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: date)
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
            selectedDate = nil // 월 변경 시 선택 초기화
        }
    }
    
    private func getDaysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let monthFirstDay = monthInterval.start
        let weekday = calendar.component(.weekday, from: monthFirstDay)
        let emptyDays = (weekday + 5) % 7
        
        var days: [Date?] = Array(repeating: nil, count: emptyDays)
        
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
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
