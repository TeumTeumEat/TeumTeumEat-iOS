//
//  SnackImageMapper.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/15/26.
//

import SwiftUI

struct SnackImageMapper {
    private static let snackImages = [
        "burger",
        "pizza",
        "chicken",
        "fry",
        "kimbab",
        "hotdog",
        "rice",
        "salad",
        "sandwich",
        "bungabbang",
        "donut",
        "pudding",
        "icecream",
        "cake",
        "cookie"
    ]
    
    /// documentId + createdAt 기반으로 간식 이미지 반환
    static func snackImage(for documentId: Int, createdAt: String) -> String {
           let key = "\(documentId)-\(createdAt)"
           let index = abs(key.hashValue) % snackImages.count
           return snackImages[index]
       }
}
