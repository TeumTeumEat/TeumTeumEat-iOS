//
//  TTETabHeader.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import SwiftUI

public struct TTETabItem: Identifiable, Equatable {
    public let id = UUID()
    public let title: String

    public init(title: String) {
        self.title = title
    }

    public static func == (lhs: TTETabItem, rhs: TTETabItem) -> Bool {
        lhs.id == rhs.id
    }
}


public struct TTETabHeader: View {
    @Binding public var selectedTab: Int
    public let tabs: [TTETabItem]
    public let indicatorColor: Color
    public let selectedTextColor: Color
    public let unselectedTextColor: Color
    public let font: Font
    public let indicatorHeight: CGFloat

    public init(
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
    
    public var body: some View {
        VStack(spacing: 0) {
            // 탭 버튼들
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = index
                        }
                    }) {
                        Text(tab.title)
                            .font(font)
                            .foregroundColor(selectedTab == index ? selectedTextColor : unselectedTextColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 51) // 고정 높이
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // 인디케이터와 구분선
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 전체 구분선
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: indicatorHeight)
                    
                    // 선택된 탭 인디케이터
                    Rectangle()
                        .fill(indicatorColor)
                        .frame(width: geometry.size.width / CGFloat(tabs.count), height: indicatorHeight)
                        .offset(x: geometry.size.width / CGFloat(tabs.count) * CGFloat(selectedTab))
                        .animation(.easeInOut(duration: 0.3), value: selectedTab)
                }
            }
            .frame(height: indicatorHeight)
        }
    }
}

public struct TTETabView<Content: View>: View {
    @State private var selectedTab: Int = 0
    public let tabs: [TTETabItem]
    public let isSwipeEnabled: Bool
    public let content: (Int) -> Content

    public init(
        tabs: [TTETabItem],
        isSwipeEnabled: Bool = true,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self.tabs = tabs
        self.isSwipeEnabled = isSwipeEnabled
        self.content = content
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Tab Header
            TTETabHeader(
                selectedTab: $selectedTab,
                tabs: tabs
            )
            
            GeometryReader { geometry in
                if isSwipeEnabled {
                    // 스와이프 가능 버전
                    TabView(selection: $selectedTab) {
                        ForEach(Array(tabs.enumerated()), id: \.offset) { index, _ in
                            content(index)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                } else {
                    // 스와이프 불가 버전
                    ZStack {
                        ForEach(Array(tabs.enumerated()), id: \.offset) { index, _ in
                            content(index)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .opacity(selectedTab == index ? 1 : 0)
                                .zIndex(selectedTab == index ? 1 : 0)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
                }
            }
        }
    }
}

struct MyView: View {
    var body: some View {
        TTETabView(
            tabs: [
                TTETabItem(title: "전체"),
                TTETabItem(title: "진행중")
            ],
            isSwipeEnabled: false
        ) { index in
            switch index {
            case 0:
                ButtonTestView()
            case 1:
                MyView2()
            default:
                EmptyView()
            }
        }
    }
}
//print("webhook test")
