//
//  ButtonTestView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/17/25.
//

import SwiftUI

struct ButtonTestView: View {
    @State private var selectedCategory: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TTEButton(title: "button", size: .large,style: .primary) {
                    print("mainButton")
                }
                
                TTEButton(title: "button", size: .large, style: .primary,backgroundColor: .EDF_0_FF,foregroundColor: ._2_B_8_FFF) {
                    print("mainButton")
                }
                
                TTEButton(title: "button", size: .large, style: .primary,backgroundColor: ._7_A_7_A_7_A,foregroundColor: .white) {
                    print("mainButton")
                }
                
                TTEButton(title: "button", size: .large ,style: .secondary) {
                    print("mainButton")
                }
                
                TTEButton(title: "button", size: .medium ,style: .primary) {
                    print("mainButton")
                }
                
                TTEButton(title: "button", size: .medium ,style: .secondary) {
                    print("mainButton")
                }
                
                TTEButton(title: "button", size: .regular ,style: .primary) {
                    print("mainButton")
                }
                
                TTEButton(title: "button", size: .regular ,style: .secondary) {
                    print("mainButton")
                }
                
                TTEButton(title: "button", size: .small ,style: .primary) {
                    print("mainButton")
                }
                
                TTEButton(title: "button", size: .small ,style: .secondary) {
                    print("mainButton")
                }
                
                TTEButton(
                    title: "iOS 개발",
                    size: .regular,
                    style: .secondary,
                    icon: Image("phone"),
                    foregroundColor: .C_8_C_8_C_8,
                    borderColor: .C_8_C_8_C_8
                ) {
                    print("프로필")
                }

                TTEButton(
                    title: "디자인",
                    size: .regular,
                    style: .secondary,
                    icon: Image("palette"),
                    iconLeadingPadding: 31.5,
                    foregroundColor: .C_8_C_8_C_8,
                    borderColor: .C_8_C_8_C_8
                ) {
                    print("디자인")
                }
                
                TTECategoryButton(
                       icon: Image("files"),
                       title: "카테고리 선택",
                       subtitle: "공부하고 싶은걸\n골라볼게요",
                       isSelected: selectedCategory == "study"
                   ) {
                       selectedCategory = "study"
                   }
            }
            .background(.white)
        }
    }
}

