//
//  OnboardingData.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import Foundation
import CoreNetwork

public struct OnboardingData: Equatable, Codable {
    public var userName: String = ""
    public var leaveHomeTime: Date?
    public var returnHomeTime: Date?
    public var dailyUsageMinutes: Int = 0
    public var contentType: ContentType = .category
    public var uploadedFileURL: URL?

    public var selectedRootCategory: String?
    public var selectedMainCategory: String?
    public var selectedSubCategory: String?
    public var selectedDetailCategory: CategoryResponse?

    public var difficulty: String?
    public var customPrompt: String = ""
    public var programWeeks: Int = 0

    public enum ContentType: String, Codable {
        case fileUpload
        case category
    }

    public init(
        userName: String = "",
        leaveHomeTime: Date? = nil,
        returnHomeTime: Date? = nil,
        dailyUsageMinutes: Int = 0,
        contentType: ContentType = .category,
        uploadedFileURL: URL? = nil,
        selectedRootCategory: String? = nil,
        selectedMainCategory: String? = nil,
        selectedSubCategory: String? = nil,
        selectedDetailCategory: CategoryResponse? = nil,
        difficulty: String? = nil,
        customPrompt: String = "",
        programWeeks: Int = 0
    ) {
        self.userName = userName
        self.leaveHomeTime = leaveHomeTime
        self.returnHomeTime = returnHomeTime
        self.dailyUsageMinutes = dailyUsageMinutes
        self.contentType = contentType
        self.uploadedFileURL = uploadedFileURL
        self.selectedRootCategory = selectedRootCategory
        self.selectedMainCategory = selectedMainCategory
        self.selectedSubCategory = selectedSubCategory
        self.selectedDetailCategory = selectedDetailCategory
        self.difficulty = difficulty
        self.customPrompt = customPrompt
        self.programWeeks = programWeeks
    }
    
    // Equatable 수동 구현
    public static func == (lhs: OnboardingData, rhs: OnboardingData) -> Bool {
        lhs.userName == rhs.userName &&
        lhs.leaveHomeTime == rhs.leaveHomeTime &&
        lhs.returnHomeTime == rhs.returnHomeTime &&
        lhs.dailyUsageMinutes == rhs.dailyUsageMinutes &&
        lhs.contentType == rhs.contentType &&
        lhs.uploadedFileURL?.absoluteString == rhs.uploadedFileURL?.absoluteString &&
        lhs.selectedRootCategory == rhs.selectedRootCategory && 
        lhs.selectedMainCategory == rhs.selectedMainCategory &&
        lhs.selectedSubCategory == rhs.selectedSubCategory &&
        lhs.selectedDetailCategory == rhs.selectedDetailCategory &&
        lhs.difficulty == rhs.difficulty &&
        lhs.customPrompt == rhs.customPrompt &&
        lhs.programWeeks == rhs.programWeeks
    }
}
