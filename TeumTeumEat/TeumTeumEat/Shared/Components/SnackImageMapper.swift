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
            // 안정적인 해시 함수 (항상 같은 결과)
            var hash = 0
            for char in key.unicodeScalars {
                hash = (hash &* 31 &+ Int(char.value)) & 0x7FFFFFFF
            }
            
            let index = hash % snackImages.count
            
            print("SnackImageMapper")
            print("- key: \(key)")
            print("- hash: \(hash)")
            print("- index: \(index)")
            print("- result: \(snackImages[index])")
            
            return snackImages[index]
        }
}
