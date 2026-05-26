//
//  OnboardingSummaryFeature .swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct OnboardingSummaryFeature {
    public init() {}
    @ObservableState
    public struct State: Equatable {
        public let userName: String
        public let leaveHomeTime: Date?
        public let returnHomeTime: Date?
        public let dailyUsageMinutes: Int
        public let programWeeks: Int
        public let contentType: OnboardingData.ContentType
        public let fileName: String?
        public let rootCategory: String?
        public let mainCategory: String?
        public let subCategory: String?
        public let detailCategory: String?
        public let difficulty: String?
        public let customPrompt: String

        public init(
            userName: String,
            leaveHomeTime: Date?,
            returnHomeTime: Date?,
            dailyUsageMinutes: Int,
            programWeeks: Int,
            contentType: OnboardingData.ContentType,
            fileName: String?,
            rootCategory: String?,
            mainCategory: String?,
            subCategory: String?,
            detailCategory: String?,
            difficulty: String?,
            customPrompt: String
        ) {
            self.userName = userName
            self.leaveHomeTime = leaveHomeTime
            self.returnHomeTime = returnHomeTime
            self.dailyUsageMinutes = dailyUsageMinutes
            self.programWeeks = programWeeks
            self.contentType = contentType
            self.fileName = fileName
            self.rootCategory = rootCategory
            self.mainCategory = mainCategory
            self.subCategory = subCategory
            self.detailCategory = detailCategory
            self.difficulty = difficulty
            self.customPrompt = customPrompt
        }

        public var leaveTimeText: String {
            guard let time = leaveHomeTime else { return "미설정" }
            return formatTime(time)
        }

        public var returnTimeText: String {
            guard let time = returnHomeTime else { return "미설정" }
            return formatTime(time)
        }

        public var usageTimeText: String {
            switch dailyUsageMinutes {
            case 5: return "3문제"
            case 7: return "5문제"
            case 10: return "7문제"
            case 15: return "10문제"
            default: return "\(dailyUsageMinutes)분"
            }
        }

        public var durationText: String {
            "\(programWeeks)주"
        }

        public var categoryText: String {
            guard let root = rootCategory,
                  let main = mainCategory,
                  let sub = subCategory,
                  let detail = detailCategory else {
                return "미설정"
            }
            return "\(root) > \(main) > \(sub) > \(detail)"
        }

        public var fileNameText: String {
            fileName ?? "없음"
        }

        public var difficultyText: String {
            difficulty ?? "미설정"
        }

        private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "a hh:mm"
            return formatter.string(from: date)
        }
    }

    public enum Action {
        case backTapped
        case completeTapped
    }

    public var body: some ReducerOf<Self> {
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
