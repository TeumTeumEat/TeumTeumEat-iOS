//
//  CategorySelectionView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

struct CategorySelectionView: View {
    let store: StoreOf<CategorySelectionFeature>
    
    var body: some View {
        switch store.currentStep {
        case .mainCategory:
            MainCategoryStepView(store: store)
        case .subCategory:
            SubCategoryStepView(store: store)
        case .detailCategory:
            DetailCategoryStepView(store: store)
        }
    }
}

struct MainCategoryStepView: View {
    let store: StoreOf<CategorySelectionFeature>
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Navigation
                HStack(spacing: 16) {
                    Button {
                        store.send(.backTapped)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                    
                    TTEProgressBar(
                        currentStep: 4,
                        totalSteps: 5,
                        height: 15
                    )
                }
                .padding(.horizontal, 24)
                
                GeometryReader { scrollGeometry in
                    ScrollView {
                        VStack(spacing: 0) {
                            Image("character_glass")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 264)
                                .padding(.horizontal, 32)
                                .padding(.top, 14)
                            
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ],
                                spacing: 12
                            ) {
                                ForEach(MainCategory.allCases, id: \.self) { category in
                                    TTEButton(
                                        title: category.rawValue,
                                        size: .grid,
                                        style: .secondary,
                                        isEnabled: true,
                                        icon: Image(category.icon),
                                        iconSize: 24,
                                        foregroundColor: .gray,
                                        borderColor: .gray
                                    ) {
                                        store.send(.mainCategorySelected(category))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            Spacer()
                                .frame(minHeight: 30)
                            
                            TTEButton(
                                title: "다음",
                                size: .large,
                                isEnabled: store.canProceed
                            ) {
                                store.send(.nextTapped)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                        }
                        .frame(minHeight: scrollGeometry.size.height)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
        }
    }
}

struct SubCategoryStepView: View {
    let store: StoreOf<CategorySelectionFeature>
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Navigation
                HStack(spacing: 16) {
                    Button {
                        store.send(.backTapped)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                    
                    TTEProgressBar(
                        currentStep: 4,
                        totalSteps: 5,
                        height: 15
                    )
                }
                .padding(.horizontal, 24)
                
                GeometryReader { scrollGeometry in
                    ScrollView {
                        VStack(spacing: 0) {
                            Image("character_glass")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 264)
                                .padding(.horizontal, 32)
                                .padding(.top, 14)
                            
                            VStack(spacing: 0) {
                                FlowLayout(spacing: 12) {
                                    if let mainCategory = store.selectedMainCategory {
                                        ForEach(mainCategory.subCategories, id: \.self) { subCategory in
                                            CategoryChip(
                                                text: subCategory.rawValue,
                                                isSelected: store.selectedSubCategory == subCategory
                                            ) {
                                                store.send(.subCategorySelected(subCategory))
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 20)
                            
                            Spacer()
                                .frame(minHeight: 30)
                            
                            TTEButton(
                                title: "다음",
                                size: .large,
                                isEnabled: store.canProceed
                            ) {
                                store.send(.nextTapped)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                        }
                        .frame(minHeight: scrollGeometry.size.height)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
        }
    }
}

struct DetailCategoryStepView: View {
    let store: StoreOf<CategorySelectionFeature>
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Navigation
                HStack(spacing: 16) {
                    Button {
                        store.send(.backTapped)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                    
                    TTEProgressBar(
                        currentStep: 4,
                        totalSteps: 5,
                        height: 15
                    )
                }
                .padding(.horizontal, 24)
                
                GeometryReader { scrollGeometry in
                    ScrollView {
                        VStack(spacing: 0) {
                            Image("character_glass")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 264)
                                .padding(.horizontal, 32)
                                .padding(.top, 14)
                            
                            detailCategoryButtons
                                .padding(.horizontal, 30)
                                .padding(.top, 20)
                            
                            Spacer()
                                .frame(minHeight: 30)
                            
                            TTEButton(
                                title: "다음",
                                size: .large,
                                isEnabled: store.canProceed
                            ) {
                                store.send(.nextTapped)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                        }
                        .frame(minHeight: scrollGeometry.size.height)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
        }
    }
    
    @ViewBuilder
    private var detailCategoryButtons: some View {
        VStack(spacing: 16) {
            if let subCategory = store.selectedSubCategory {
                ForEach(subCategory.detailCategories, id: \.self) { detailCategory in
                    let isSelected = store.selectedDetailCategory == detailCategory
                    
                    TTEButton(
                        title: detailCategory.rawValue,
                        size: .large,
                        style: isSelected ? .primary : .secondary, isEnabled: true
                    ) {
                        store.send(.detailCategorySelected(detailCategory))
                    }
                }
            }
        }
    }
}

struct CategoryChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isSelected ? Color.blue : Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1.5)
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            let position = CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y  
            )
            subview.place(at: position, proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    // 다음 줄로
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
