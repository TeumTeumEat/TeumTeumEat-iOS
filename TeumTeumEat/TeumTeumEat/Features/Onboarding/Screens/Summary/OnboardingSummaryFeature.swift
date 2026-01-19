//
//  OnboardingSummaryFeature .swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import ComposableArchitecture
import Foundation

@Reducer
struct OnboardingSummaryFeature {
    @ObservableState
    struct State: Equatable {
        let userName: String
        let leaveHomeTime: Date?
        let returnHomeTime: Date?
        let dailyUsageMinutes: Int
        let programWeeks: Int
        let contentType: OnboardingData.ContentType
        let fileName: String?
        let rootCategory: String?
        let mainCategory: String?
        let subCategory: String?
        let detailCategory: String?
        let difficulty: String?
        let customPrompt: String
        
        var leaveTimeText: String {
            guard let time = leaveHomeTime else { return "미설정" }
            return formatTime(time)
        }
        
        var returnTimeText: String {
            guard let time = returnHomeTime else { return "미설정" }
            return formatTime(time)
        }
        
        var usageTimeText: String {
            "\(dailyUsageMinutes)분"
        }
        
        var durationText: String {
            "\(programWeeks)주"
        }
        
        var categoryText: String {
            guard let root = rootCategory,
                  let main = mainCategory,
                  let sub = subCategory,
                  let detail = detailCategory else {
                return "미설정"
            }
            return "\(root) > \(main) > \(sub) > \(detail)"
        }
        
        var fileNameText: String {
            fileName ?? "없음"
        }
        
        var difficultyText: String {
            difficulty ?? "미설정"
        }
        
        private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "a hh:mm"
            return formatter.string(from: date)
        }
    }
    
    enum Action {
        case backTapped
        case completeTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backTapped:
                return .none
                
            case .completeTapped:
                return .none
            }
        }
    }
}
