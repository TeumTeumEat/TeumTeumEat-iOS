//
//  HistoryView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture
import OnboardingFeature

struct HistoryView: View {
    @Bindable var store: StoreOf<HistoryFeature>
    
    var body: some View {
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
            scrollContent
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .trackScreen(.history)
        .navigationDestination(
            item: $store.scope(state: \.historyDetailSummary, action: \.historyDetailSummary)
        ) { detailStore in
            HistoryDetailSummaryView(store: detailStore)
        }
    }

    private var scrollContent: some View {
        ScrollViewReader { proxy in
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
                            dateTabView
                        case 1:
                            topicTabView
                        default:
                            EmptyView()
                        }
                    }
                }
                .onChange(of: store.selectedDateString) { oldValue, newValue in
                    if newValue != nil {
                        // Cell이 렌더링될 시간을 주고 스크롤
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("calendar", anchor: .center)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var dateTabView: some View {
        VStack(spacing: 16) {
            HistoryDateCard(fireCount: store.fireCount)

            if let calendarError = store.calendarError {
                InlineErrorView(
                    message: calendarError,
                    onRetry: { store.send(.retryCalendar) }
                )
            } else {
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
                    onMonthChanged: { year, month in store.send(.monthChanged(year: year, month: month)) },
                    onDateSelected: { dateString in store.send(.dateSelected(dateString)) },
                    onItemTapped: { id, type, date in store.send(.historyItemTapped(id: id, type: type, date: date)) }
                )
                .padding(.top, 5)
                .id("calendar")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 120)
    }

    private var topicTabView: some View {
        VStack(spacing: 16) {
            Button { store.send(.filterToggled) } label: {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(store.showOnlyActive ? Color.blue500 : Color.clear)
                            .frame(width: 20, height: 20)
                        Circle()
                            .stroke(store.showOnlyActive ? Color.blue500 : Color.gray300, lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                        if store.showOnlyActive {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    Text("진행중인 주제 보기")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(store.showOnlyActive ? .blue500 : .gray600)
                    Spacer()
                }
            }

            if store.isLoadingTopics {
                ProgressView().frame(maxWidth: .infinity, maxHeight: 300)
            } else if let topicError = store.topicError {
                InlineErrorView(message: topicError, onRetry: { store.send(.retryTopicHistories) })
            } else if store.filteredTopicCategories.isEmpty {
                Text(store.showOnlyActive ? "진행중인 주제의 히스토리가 없습니다" : "주제별 히스토리가 없습니다")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: 300)
            } else {
                ForEach(store.filteredTopicCategories) { category in
                    topicCategoryRow(category)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
        .padding(.bottom, 120)
    }

    private func topicCategoryRow(_ category: HistoryCategoryResponse) -> some View {
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
                guard let id = Int(item.id),
                      let history = category.histories.first(where: { $0.id == id }) else { return }
                store.send(.historyItemTapped(id: id, type: history.type, date: String(history.lastStudiedAt.prefix(10))))
            }
        )
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
    
    private var fireColor: Color {
        fireCount == 0 ? .gray900 : .red400
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
    
    private var streakInfo: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack(spacing: 8) {
                Image("fire")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(fireColor)
                    .frame(width: 50, height: 50)
                
                Text("\(fireCount)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(fireColor)
            }
            .frame(height: 66)
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            Text(streakText)
                .stSemibold16()
                .foregroundColor(.gray900)
                .frame(height: 42)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity)
        .padding(.trailing, 24)
        .background(Color(hex: "EAF4FF"))
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 8) {
                streakInfo
                
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
