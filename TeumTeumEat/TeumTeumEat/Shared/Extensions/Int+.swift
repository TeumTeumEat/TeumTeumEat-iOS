//
//  Int+.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/11/25.
//

import Foundation

extension Int {
    var withCommas: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
