//
//  OnboardingData.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import Foundation

struct OnboardingData: Equatable, Codable {
    var userName: String = ""
    var leaveHomeTime: Date?
    var returnHomeTime: Date?
    var dailyUsageMinutes: Int = 0
    var contentType: ContentType = .category
    var uploadedFileURL: URL?

    var selectedMainCategory: String?
    var selectedSubCategory: String?
    var selectedDetailCategory: CategoryResponse?
    
    var difficulty: String?
    var customPrompt: String = ""
    var programWeeks: Int = 0
    
    enum ContentType: String, Codable {
        case fileUpload
        case category
    }
    
    // Equatable 수동 구현
    static func == (lhs: OnboardingData, rhs: OnboardingData) -> Bool {
        lhs.userName == rhs.userName &&
        lhs.leaveHomeTime == rhs.leaveHomeTime &&
        lhs.returnHomeTime == rhs.returnHomeTime &&
        lhs.dailyUsageMinutes == rhs.dailyUsageMinutes &&
        lhs.contentType == rhs.contentType &&
        lhs.uploadedFileURL?.absoluteString == rhs.uploadedFileURL?.absoluteString && 
        lhs.selectedMainCategory == rhs.selectedMainCategory &&
        lhs.selectedSubCategory == rhs.selectedSubCategory &&
        lhs.selectedDetailCategory == rhs.selectedDetailCategory &&
        lhs.difficulty == rhs.difficulty &&
        lhs.customPrompt == rhs.customPrompt &&
        lhs.programWeeks == rhs.programWeeks
    }
}
