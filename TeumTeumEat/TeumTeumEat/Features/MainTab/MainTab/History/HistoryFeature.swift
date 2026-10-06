//
//  HistoryFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture
import OnboardingFeature

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
        var calendarError: String? = nil
        var topicError: String? = nil

        var showOnlyActive: Bool = false
        var activeGoals: [GoalResponse] = []

        var filteredTopicCategories: [HistoryCategoryResponse] {
            guard showOnlyActive, !activeGoals.isEmpty else { return topicCategories }
            let activeNames: Set<String> = Set(activeGoals.compactMap { goal -> String? in
                goal.type == "CATEGORY" ? goal.category?.name : goal.fileName
            })
            return topicCategories.filter { activeNames.contains($0.categoryName) }
        }

        @Presents var historyDetailSummary: HistoryDetailSummaryFeature.State?
    }
    
    enum Action {
        case onAppear
        case settingTapped
        case leagueTapped
        case tabSelected(Int)
        case monthChanged(year: Int, month: Int)
        case dateSelected(String?)
        case calendarDataLoaded(Result<CalendarHistoryData, Error>)
        case historyItemsLoaded(Result<[HistoryItemResponse], Error>)
        case fetchTopicHistories
        case topicHistoriesLoaded(Result<[HistoryCategoryResponse], Error>)
        case activeGoalsLoaded(Result<[GoalResponse], Error>)
        case retryCalendar
        case retryTopicHistories
        case filterToggled
        case historyItemTapped(id: Int, type: String, date: String)
        case historyDetailSummary(PresentationAction<HistoryDetailSummaryFeature.Action>)
        case delegate(Delegate)
    }
    
    enum Delegate {
        case openMyPageRequested
        case openLeagueRequested
    }
    
    @Dependency(\.goalClient) var goalClient
    
    @Dependency(\.historyClient) var historyClient
    @Dependency(\.analyticsClient) var analyticsClient
    var body: some ReducerOf<Self> {
         Reduce { state, action in
             switch action {
             case .onAppear:
                 return .run { [year = state.currentYear, month = state.currentMonth] send in
                     await send(.monthChanged(year: year, month: month))
                     await send(.fetchTopicHistories)
                 }
                 
             case .settingTapped:
                 return .send(.delegate(.openMyPageRequested))

             case .leagueTapped:
                 return .send(.delegate(.openLeagueRequested))
                 
             case .tabSelected(let index):
                 state.selectedTab = index
                 analyticsClient.log(.historyTabSelect(tab: index == 0 ? "date" : "topic"))
                 
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
                             try await historyClient.fetchCalendarHistory(year: year, month: month)
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
                              try await historyClient.fetchHistoryByDate(dateString)
                          }
                      ))
                  }
                 
             case .calendarDataLoaded(.success(let data)):
                 state.calendarData = data
                 state.calendarError = nil
                 // stampCount를 totalStamps로 업데이트
                 state.fireCount = data.currentStreak
                 state.stampCount = data.totalStamps
                 Log.history.debug("Calendar data loaded: \(data.currentStreak) stamped dates, total: \(data.totalStamps)")
                 return .none

             case .calendarDataLoaded(.failure(let error)):
                 let msg = (error as? APIError)?.overlayMessage ?? "에러가 발생했습니다."
                 state.calendarError = msg
                 Log.history.error("Failed to load calendar data: \(error)")
                 return .none
                 
             case .historyItemsLoaded(.success(let items)):
                  state.selectedDateHistoryItems = items
                  Log.history.debug("History items loaded: \(items.count) items")
                  return .none
                  
              case .historyItemsLoaded(.failure(let error)):
                  Log.history.error("Failed to load history items: \(error)")
                  state.selectedDateHistoryItems = []
                  return .none
                 
             case .fetchTopicHistories:
                 state.isLoadingTopics = true
                 return .run { send in
                     await withTaskGroup(of: Void.self) { group in
                         group.addTask {
                             await send(.topicHistoriesLoaded(
                                 Result { try await historyClient.fetchHistoryTopics() }
                             ))
                         }
                         group.addTask {
                             await send(.activeGoalsLoaded(
                                 Result { try await goalClient.fetchGoals() }
                             ))
                         }
                     }
                 }

             case .activeGoalsLoaded(.success(let goals)):
                 state.activeGoals = goals.filter { !$0.isExpired && !$0.isCompleted }
                 return .none

             case .activeGoalsLoaded(.failure):
                 return .none

             case .retryCalendar:
                 state.calendarError = nil
                 return .run { [year = state.currentYear, month = state.currentMonth] send in
                     await send(.calendarDataLoaded(
                         Result { try await historyClient.fetchCalendarHistory(year: year, month: month) }
                     ))
                 }

             case .retryTopicHistories:
                 state.topicError = nil
                 return .send(.fetchTopicHistories)

             case .filterToggled:
                 state.showOnlyActive.toggle()
                 return .none

             case .topicHistoriesLoaded(.success(let categories)):
                 state.isLoadingTopics = false
                 state.topicError = nil
                 state.topicCategories = categories
                 Log.history.debug("Topic histories loaded: \(categories.count) categories")
                 return .none

             case .topicHistoriesLoaded(.failure(let error)):
                 state.isLoadingTopics = false
                 let msg = (error as? APIError)?.overlayMessage ?? "에러가 발생했습니다."
                 state.topicError = msg
                 Log.history.error("Failed to load topic histories: \(error)")
                 return .none
                 
             case .historyItemTapped(let id, let typeString, let date):
                 // String -> DocumentType 변환
                 let documentType: DocumentType = typeString == "CATEGORY" ? .category : .document
                 
                 state.historyDetailSummary = HistoryDetailSummaryFeature.State(
                    historyId: id,
                    documentType: documentType,
                    date: date
                 )
                 Log.history.debug("History item tapped - ID: \(id), Type: \(documentType), Date: \(date)")
                 return .none
                  
              case .historyDetailSummary(.presented(.delegate(.dismissed))):
                  state.historyDetailSummary = nil
                  Log.history.debug("History detail dismissed")
                  return .none
                  
              case .historyDetailSummary:
                  return .none

                 
             case .delegate:
                 return .none
             }
         }
         .ifLet(\.$historyDetailSummary, action: \.historyDetailSummary) {
             HistoryDetailSummaryFeature()
         }
     }
 }
