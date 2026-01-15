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
        
        var selectedDateHistoryItems: [HistoryItemResponse] = []
        var selectedDateString: String?
        
        var topicCategories: [HistoryCategoryResponse] = []
        var isLoadingTopics: Bool = false
        
        var historyDetailSummary: HistoryDetailSummaryFeature.State?
    }
    
    enum Action {
        case onAppear
        case settingTapped
        case tabSelected(Int)
        case monthChanged(year: Int, month: Int)
        case dateSelected(String?)
        case calendarDataLoaded(Result<CalendarHistoryData, Error>)
        case historyItemsLoaded(Result<[HistoryItemResponse], Error>)
        case fetchTopicHistories
        case topicHistoriesLoaded(Result<[HistoryCategoryResponse], Error>)
        case historyItemTapped(id: Int, type: String, date: String)
        case historyDetailSummary(HistoryDetailSummaryFeature.Action)
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
                 
                 // 주제별 탭으로 전환 시 데이터 로드
                 if index == 1 && state.topicCategories.isEmpty {
                     return .send(.fetchTopicHistories)
                 }
                 return .none
                 
                 
             case .monthChanged(let year, let month):
                 state.currentYear = year
                 state.currentMonth = month
                 state.selectedDateString = nil // 월 변경 시 선택 초기화
                 state.selectedDateHistoryItems = []
                 
                 return .run { send in
                     await send(.calendarDataLoaded(
                         Result {
                             try await apiClient.fetchCalendarHistory(year: year, month: month)
                         }
                     ))
                 }
                 
             case .dateSelected(let dateString):
                  state.selectedDateString = dateString
                  
                  guard let dateString = dateString else {
                      // 선택 해제
                      state.selectedDateHistoryItems = []
                      return .none
                  }
                  
                  // 선택된 날짜의 히스토리 조회
                  return .run { send in
                      await send(.historyItemsLoaded(
                          Result {
                              try await apiClient.fetchHistoryByDate(dateString)
                          }
                      ))
                  }
                 
             case .calendarDataLoaded(.success(let data)):
                 state.calendarData = data
                 // stampCount를 totalStamps로 업데이트
                 state.fireCount = data.currentStreak
                 state.stampCount = data.totalStamps
                 print("Calendar data loaded: \(data.currentStreak) stamped dates, total: \(data.totalStamps)")
                 return .none
                 
             case .calendarDataLoaded(.failure(let error)):
                 print("    Failed to load calendar data: \(error)")
                 return .none
                 
             case .historyItemsLoaded(.success(let items)):
                  state.selectedDateHistoryItems = items
                  print("History items loaded: \(items.count) items")
                  return .none
                  
              case .historyItemsLoaded(.failure(let error)):
                  print("Failed to load history items: \(error)")
                  state.selectedDateHistoryItems = []
                  return .none
                 
             case .fetchTopicHistories:
                 state.isLoadingTopics = true
                 return .run { send in
                     await send(.topicHistoriesLoaded(
                        Result {
                            try await apiClient.fetchHistoryTopics()
                        }
                     ))
                 }
                 
             case .topicHistoriesLoaded(.success(let categories)):
                 state.isLoadingTopics = false
                 state.topicCategories = categories
                 print("Topic histories loaded: \(categories.count) categories")
                 return .none
                 
             case .topicHistoriesLoaded(.failure(let error)):
                 state.isLoadingTopics = false
                 print("Failed to load topic histories: \(error)")
                 return .none
                 
             case .historyItemTapped(let id, let typeString, let date):
                 // String -> DocumentType 변환
                 let documentType: DocumentType = typeString == "CATEGORY" ? .category : .document
                 
                 state.historyDetailSummary = HistoryDetailSummaryFeature.State(
                    historyId: id,
                    documentType: documentType,
                    date: date
                 )
                 print("History item tapped - ID: \(id), Type: \(documentType), Date: \(date)")
                 return .none
                  
              case .historyDetailSummary(.delegate(.dismissed)):
                  state.historyDetailSummary = nil
                  print("History detail dismissed")
                  return .none
                  
              case .historyDetailSummary:
                  return .none

                 
             case .delegate:
                 return .none
             }
         }
         .ifLet(\.historyDetailSummary, action: \.historyDetailSummary) {
             HistoryDetailSummaryFeature()
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
                                        fireCount: store.fireCount
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
                                        selectedDateString: store.selectedDateString,
                                        historyItems: store.selectedDateHistoryItems,
                                        onMonthChanged: { year, month in
                                            store.send(.monthChanged(year: year, month: month))
                                        },
                                        onDateSelected: { dateString in
                                            store.send(.dateSelected(dateString))
                                        },
                                        onItemTapped: { id, type, date in
                                            store.send(.historyItemTapped(id: id, type: type, date: date))
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
                                     if store.isLoadingTopics {
                                         ProgressView()
                                             .frame(maxWidth: .infinity, maxHeight: 300)
                                     } else if store.topicCategories.isEmpty {
                                         Text("주제별 히스토리가 없습니다")
                                             .foregroundColor(.gray)
                                             .frame(maxWidth: .infinity, maxHeight: 300)
                                     } else {
                                         ForEach(store.topicCategories) { category in
                                             ExpandableSummaryRow(
                                                 categories: [category.categoryName],
                                                 items: category.histories.map { history in
                                                     QuizHistoryItem(
                                                        id: "\(history.id)",
                                                        title: history.title,
                                                        dateText: formatDate(history.lastStudiedAt),
                                                        summarySnippet: history.summarySnippet,
                                                        isStreak: false
                                                     )
                                                 },
                                                 onItemTapped: { item in
                                                     print("선택된 항목: \(item.title)")
                                                 }
                                             )
                                         }
                                     }
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
            .background(Color.white)
            .navigationBarHidden(true)
            .navigationDestination(
                isPresented: Binding(
                    get: { store.historyDetailSummary != nil },
                    set: { if !$0 { store.send(.historyDetailSummary(.delegate(.dismissed))) } }
                )
            ) {
                if let detailStore = store.scope(state: \.historyDetailSummary, action: \.historyDetailSummary) {
                    HistoryDetailSummaryView(store: detailStore)
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
    
    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: isoString) else {
            return isoString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MM.dd"
        
        return displayFormatter.string(from: date)
    }
}



struct HistoryDateCard: View {
    let fireCount: Int
    
    private var streakText: String {
        switch fireCount {
        case 0:
            return "얼른 시작 틈틈잇"
        case 1...6:
            return "시작이 반이다"
        case 7...29:
            return "일주일 연속 틈틈잇!"
        case 30...:
            return "한 달 연속 틈틈잇!"
        default:
            return "얼른 시작 틈틈잇"
        }
    }
    
    private var streakImage: String {
        switch fireCount {
        case 0:
            return "Frame 7407"
        case 1...6:
            return "Frame 7408"
        case 7...29:
            return "Frame 7409"
        case 30...:
            return "Frame 7410"
        default:
            return "Frame 7407"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 8) {
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
                    
                    Text(streakText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(height: 42)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: .infinity)
                .background(Color(hex: "EAF4FF"))
                
                Image(streakImage)
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
                .bdMedium14_20()
                .foregroundColor(.blue500)
            
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(.blue500)
            
            Text("\(count)")
                .tBold20()
                .foregroundColor(.blue500)
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
    let stampedDates: [String] // "2026-01-04" 형식
    let selectedDateString: String? // 선택된 날짜 문자열
    let historyItems: [HistoryItemResponse] // 선택된 날짜의 히스토리 아이템
    let onMonthChanged: (Int, Int) -> Void
    let onDateSelected: (String?) -> Void // 날짜 선택/해제 콜백
    let onItemTapped: (Int, String, String) -> Void
    
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
            if selectedDateString != nil, !historyItems.isEmpty {
                selectedDateInfo()
                    .padding(.top, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedDateString)
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
                    .font(.system(size: 24, weight: .semibold))
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
                    .font(.system(size: 24, weight: .semibold))
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
                    let dateString = dateToString(date)
                    let hasQuiz = stampedDates.contains(dateString)
                    
                    DayCell(
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
                } else {
                    Color.clear
                        .frame(height: 40)
                }
            }
        }
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
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: currentMonthDate)
    }
    
    private func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS" 
        
        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "ko_KR")
        outputFormatter.dateFormat = "M월 d일"
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        
        // 파싱 실패 시 앞부분만 잘라서 표시
        if dateString.count >= 10 {
            let dateOnly = String(dateString.prefix(10)) // "2026-01-04"
            let fallbackFormatter = DateFormatter()
            fallbackFormatter.dateFormat = "yyyy-MM-dd"
            if let date = fallbackFormatter.date(from: dateOnly) {
                return outputFormatter.string(from: date)
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
