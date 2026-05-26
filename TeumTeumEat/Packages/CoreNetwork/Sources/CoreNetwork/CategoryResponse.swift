//
//  CategoryResponse.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation

public struct CategoryData: Codable, Equatable {
    public let categoryResponses: [CategoryResponse]

    public init(categoryResponses: [CategoryResponse]) {
        self.categoryResponses = categoryResponses
    }
}

public struct CategoryResponse: Codable, Equatable, Identifiable {
    public let categoryId: Int
    public let name: String
    public let path: String

    public var id: Int { categoryId }

    public var pathComponents: [String] {
        path.components(separatedBy: "/")
    }

    public var mainCategory: String? {
        pathComponents.count > 1 ? pathComponents[1] : nil
    }

    public var subCategory: String? {
        pathComponents.count > 2 ? pathComponents[2] : nil
    }

    public init(categoryId: Int, name: String, path: String) {
        self.categoryId = categoryId
        self.name = name
        self.path = path
    }
}
