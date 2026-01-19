//
//  CategoryResponse.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation

struct CategoryData: Codable, Equatable {
    let categoryResponses: [CategoryResponse]
}

struct CategoryResponse: Codable, Equatable, Identifiable {
    let categoryId: Int
    let name: String
    let path: String
    
    var id: Int { categoryId }
    
    var pathComponents: [String] {
        path.components(separatedBy: "/") 
    }
    
    var mainCategory: String? {
        pathComponents.count > 1 ? pathComponents[1] : nil
    }
    
    var subCategory: String? {
        pathComponents.count > 2 ? pathComponents[2] : nil
    }
}
