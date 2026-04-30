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
    var showProgressBar: Bool = true
    
    var body: some View {
        Group {
            if store.isLoading {
                LoadingView()
            } else if let error = store.loadError {
                CategoryErrorView(
                    error: error,
                    onRetry: { store.send(.retryLoad) }
                )
            } else {
                
                let _ = print("현재 Step: \(store.currentStep)")
                let _ = print("categories 개수: \(store.categories.count)")
                switch store.currentStep {
                case .rootCategory:
                    let _ = print("RootCategory 화면 표시!")
                    RootCategoryStepView(store: store, showProgressBar: showProgressBar)
                case .mainCategory:
                    let _ = print("MainCategory 화면 표시!")
                    MainCategoryStepView(store: store, showProgressBar: showProgressBar)
                case .subCategory:
                    SubCategoryStepView(store: store, showProgressBar: showProgressBar)
                case .detailCategory:
                    DetailCategoryStepView(store: store, showProgressBar: showProgressBar)
                }
            }
        }
        .background(.white)
        .colorScheme(.light)
        .onAppear {
            store.send(.onAppear)
        }
    }
}

struct CategoryErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("카테고리를 불러올 수 없습니다")
                .font(.headline)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TTEButton(
                title: "다시 시도",
                size: .large,
                isEnabled: true
            ) {
                onRetry()
            }
            .padding(.horizontal, 20)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.gray900)
            
            Text("카테고리를 불러오는 중...")
                .font(.subheadline)
                .foregroundColor(.gray600)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
        .colorScheme(.light)
    }
}

struct RootCategoryStepView: View {
    let store: StoreOf<CategorySelectionFeature>
    var showProgressBar: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Navigation
                HStack(spacing: 16) {
                    Button {
                        store.send(.backTapped)
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .frame(width: 24, height: 24,alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    
                    if showProgressBar {
                        TTEProgressBar(
                            currentStep: 2,
                            totalSteps: 5,
                            height: 15
                        )
                    } else {
                        Spacer()
                        Text("카테고리 선택")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                        Color.clear.frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 20)
                
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
                                ForEach(store.rootCategories, id: \.self) { category in
                                    CategoryGridButton(
                                        title: category,
                                        icon: category.categoryIcon,
                                        isSelected: store.selectedRootCategory == category
                                    ) {
                                        store.send(.rootCategorySelected(category))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            Spacer()
                                .frame(minHeight: 30)
                            
                            TTEButton(
                                title: "다음으로",
                                size: .largeFull,
                                isEnabled: store.canProceed
                            ) {
                                store.send(.nextTapped)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                        }
                        .frame(minHeight: scrollGeometry.size.height)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .background(.white)
        }
        .colorScheme(.light)
    }
}

struct MainCategoryStepView: View {
    let store: StoreOf<CategorySelectionFeature>
    var showProgressBar: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Navigation
                HStack(spacing: 16) {
                    Button {
                        store.send(.backTapped)
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .frame(width: 24, height: 24, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    
                    if showProgressBar {
                        TTEProgressBar(
                            currentStep: 2,
                            totalSteps: 5,
                            height: 15
                        )
                    } else {
                        Spacer()
                        Text("카테고리 선택")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                        Color.clear.frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 20)
                
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
                                ForEach(store.mainCategories, id: \.self) { category in
                                    CategoryGridButton(
                                        title: category,
                                        icon: category.categoryIcon,
                                        isSelected: store.selectedMainCategory == category
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
                                title: "다음으로",
                                size: .largeFull,
                                isEnabled: store.canProceed
                            ) {
                                store.send(.nextTapped)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                        }
                        .frame(minHeight: scrollGeometry.size.height)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .background(.white)
        }
        .colorScheme(.light)
    }
}

struct SubCategoryStepView: View {
    let store: StoreOf<CategorySelectionFeature>
    var showProgressBar: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Navigation
                HStack(spacing: 16) {
                    Button {
                        store.send(.backTapped)
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .frame(width: 24, height: 24, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    
                    if showProgressBar {
                        TTEProgressBar(
                            currentStep: 2,
                            totalSteps: 5,
                            height: 15
                        )
                    } else {
                        Spacer()
                        Text("카테고리 선택")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                        Color.clear.frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 20)
                
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
                                    ForEach(store.currentSubCategories, id: \.self) { subCategory in
                                        CategoryChip(
                                            text: subCategory,
                                            isSelected: store.selectedSubCategory == subCategory
                                        ) {
                                            store.send(.subCategorySelected(subCategory))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 20)
                            
                            Spacer()
                                .frame(minHeight: 30)
                            
                            TTEButton(
                                title: "다음으로",
                                size: .largeFull,
                                isEnabled: store.canProceed
                            ) {
                                store.send(.nextTapped)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                        }
                        .frame(minHeight: scrollGeometry.size.height)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .background(.white)
        }
        .colorScheme(.light)
    }
}

struct DetailCategoryStepView: View {
    let store: StoreOf<CategorySelectionFeature>
    var showProgressBar: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation
            HStack(spacing: 16) {
                Button {
                    store.send(.backTapped)
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .frame(width: 24, height: 24, alignment: .leading)
                        .contentShape(Rectangle())
                }
                
                if showProgressBar {
                    TTEProgressBar(
                        currentStep: 4,
                        totalSteps: 5,
                        height: 15
                    )
                } else {
                    Spacer()
                    Text("카테고리 선택")
                        .font(.system(size: 18, weight: .semibold))
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
            }
            .padding(.horizontal, 20)
            
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
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        Spacer()
                            .frame(minHeight: 30)
                        
                        TTEButton(
                            title: "다음으로",
                            size: .largeFull,
                            isEnabled: store.canProceed
                        ) {
                            store.send(.nextTapped)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                    .frame(minHeight: scrollGeometry.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .background(.white)
        .colorScheme(.light)
    }
    
    @ViewBuilder
    private var detailCategoryButtons: some View {
        VStack(spacing: 16) {
            ForEach(store.currentDetailCategories) { detailCategory in
                let isSelected = store.selectedDetailCategory?.id == detailCategory.id
                
                TTEButton(
                    title: detailCategory.name,
                    size: .large,
                    style: .secondary,
                    isEnabled: true,
                    foregroundColor: isSelected ? .blue500 : .gray600,
                    borderColor: isSelected ? .blue500 : .gray300
                ) {
                    store.send(.detailCategorySelected(detailCategory))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct CategoryChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .btSemiBold20_24()
                .foregroundColor(isSelected ? .blue500 : .gray600)
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.blue500 : Color.gray300, lineWidth: 2)
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

struct CategoryGridButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(icon)
                    .resizable()
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .btSemiBold20_24()
                    .foregroundColor(isSelected ? .blue500 : .gray600)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue500 : Color.gray300, lineWidth: 2)
            )
        }
    }
}
