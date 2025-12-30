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

    var selectedMainCategory: MainCategory?
    var selectedSubCategory: SubCategory?
    var selectedDetailCategory: DetailCategory?
    
    var difficulty: String?
    var customPrompt: String = ""
    var programWeeks: Int = 0   
    
    enum ContentType: String, Codable {
        case fileUpload
        case category
    }
}
