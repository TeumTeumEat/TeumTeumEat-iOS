//
//  TTEProgressBar.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import SwiftUI

public struct TTEProgressBar: View {
    public let currentStep: Int
    public let totalSteps: Int
    public let progressColor: Color
    public let backgroundColor: Color
    public let height: CGFloat
    public let showStepText: Bool
    public let cornerRadius: CGFloat

    public init(
        currentStep: Int,
        totalSteps: Int = 5,
        progressColor: Color = Color(hex: "2B8FFF"),
        backgroundColor: Color = Color(hex: "E0E0E0"),
        height: CGFloat = 8,
        showStepText: Bool = true,
        cornerRadius: CGFloat = 16
    ) {
        self.currentStep = currentStep
        self.totalSteps = totalSteps
        self.progressColor = progressColor
        self.backgroundColor = backgroundColor
        self.height = height
        self.showStepText = showStepText
        self.cornerRadius = cornerRadius
    }
    
    private var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStep) / Double(totalSteps)
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경 바
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor)
                        .frame(height: height)
                    
                    // 진행 바 (차오르는 부분)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(progressColor)
                        .frame(
                            width: geometry.size.width * progress,
                            height: height
                        )
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: height)
            
            if showStepText {
                Text("\(currentStep)/\(totalSteps)")
                    .cRegular14()
                    .foregroundColor(.black)
                    .frame(width: 40)
            }
        }
    }
}
