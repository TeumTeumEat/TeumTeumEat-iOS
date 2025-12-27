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
        let leaveHomeTime: Date?
        let returnHomeTime: Date?
        let dailyUsageMinutes: Int
        let programWeeks: Int
        
        var leaveTimeText: String {
            guard let time = leaveHomeTime else { return "-" }
            return formatTime(time)
        }
        
        var returnTimeText: String {
            guard let time = returnHomeTime else { return "-" }
            return formatTime(time)
        }
        
        var usageTimeText: String {
            "\(dailyUsageMinutes)분"
        }
        
        var durationText: String {
            "\(programWeeks)주"
        }
        
        private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "a h:mm"
            formatter.locale = Locale(identifier: "ko_KR")
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
