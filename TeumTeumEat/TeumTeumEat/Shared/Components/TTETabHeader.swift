//
//  TTETabHeader.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import SwiftUI

struct TTETabItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    
    static func == (lhs: TTETabItem, rhs: TTETabItem) -> Bool {
        lhs.id == rhs.id
    }
}


struct TTETabHeader: View {
    @Binding var selectedTab: Int
    let tabs: [TTETabItem]
    let indicatorColor: Color
    let selectedTextColor: Color
    let unselectedTextColor: Color
    let font: Font
    let indicatorHeight: CGFloat
    
    init(
        selectedTab: Binding<Int>,
        tabs: [TTETabItem],
        indicatorColor: Color = Color(hex: "2B8FFF"),
        selectedTextColor: Color = Color(hex: "2B8FFF"),
        unselectedTextColor: Color = Color(hex: "7A7A7A"),
        font: Font = .system(size: 16, weight: .semibold),
        indicatorHeight: CGFloat = 2
    ) {
        self._selectedTab = selectedTab
        self.tabs = tabs
        self.indicatorColor = indicatorColor
        self.selectedTextColor = selectedTextColor
        self.unselectedTextColor = unselectedTextColor
        self.font = font
        self.indicatorHeight = indicatorHeight
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = index
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(tab.title)
                                .font(font)
                                .foregroundColor(selectedTab == index ? selectedTextColor : unselectedTextColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            
                            // 선택된 탭의 인디케이터
                            Rectangle()
                                .fill(selectedTab == index ? indicatorColor : Color.clear)
                                .frame(height: indicatorHeight)
                        }
                        .frame(maxWidth: .infinity) 
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // 전체 하단 구분선
            Divider()
        }
    }
}

struct TTETabView<Content: View>: View {
    @State private var selectedTab: Int = 0
    let tabs: [TTETabItem]
    let content: (Int) -> Content
    
    init(
        tabs: [TTETabItem],
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self.tabs = tabs
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Header
            TTETabHeader(
                selectedTab: $selectedTab,
                tabs: tabs
            )
            
            // Content
            TabView(selection: $selectedTab) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, _ in
                    content(index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

struct MyView: View {
    var body: some View {
        TTETabView(
            tabs: [
                TTETabItem(title: "전체"),
                TTETabItem(title: "진행중")
            ]
        ) { index in
            switch index {
            case 0:
                ButtonTestView()
            case 1:
                ContentView()
            default:
                EmptyView()
            }
        }
    }
}
//print("webhook test")
