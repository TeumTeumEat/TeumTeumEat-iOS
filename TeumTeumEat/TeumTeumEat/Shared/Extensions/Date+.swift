//
//  Date.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/11/25.
//

import Foundation

extension Date {
    func toString(format: String = "yyyy-MM-dd") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self)
    }
}
