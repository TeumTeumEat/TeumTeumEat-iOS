//
//  TTEToastModifier.swift
//  DesignSystem
//
//  Created by 임재현 on 6/21/26.
//

import SwiftUI

public struct TTEToastModifier: ViewModifier {
    @Binding public var isPresented: Bool
    public let message: String

    public func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content

            if isPresented {
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 60)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isPresented = false
                            }
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

public extension View {
    func tteToast(isPresented: Binding<Bool>, message: String) -> some View {
        self.modifier(TTEToastModifier(isPresented: isPresented, message: message))
    }
}
