//
//  ButtonTestView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/17/25.
//

import SwiftUI

struct ButtonTestView: View {
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
            }
            .background(.white)
        }
    }
}

