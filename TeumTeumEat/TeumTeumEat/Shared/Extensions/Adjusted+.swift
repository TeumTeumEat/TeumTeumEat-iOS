//
//  Adjusted+.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/11/25.
//

import UIKit

public enum DesignGuide {
    static let width: CGFloat = 375
    static let height: CGFloat = 812
}

public extension CGFloat {
    var adjusted: CGFloat {
        let ratio: CGFloat = UIScreen.main.bounds.width / DesignGuide.width
        return self * ratio
    }
    
    var adjustedH: CGFloat {
        let ratio: CGFloat = UIScreen.main.bounds.height / DesignGuide.height
        return self * ratio
    }
}

public extension Double {
    var adjusted: Double {
        let ratio: Double = Double(UIScreen.main.bounds.width / DesignGuide.width)
        return self * ratio
    }
    
    var adjustedH: Double {
        let ratio: Double = Double(UIScreen.main.bounds.height / DesignGuide.height)
        return self * ratio
    }
}
