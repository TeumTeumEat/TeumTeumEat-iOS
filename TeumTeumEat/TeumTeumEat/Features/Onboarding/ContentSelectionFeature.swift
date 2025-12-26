//
//  ContentSelectionFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/22/25.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct ContentSelectionFeature {
    @ObservableState
    struct State: Equatable {
        var selectedType: ContentType?
        
        var canProceed: Bool {
            selectedType != nil
        }
        
        enum ContentType {
            case fileUpload
            case category
        }
    }
    
    enum Action {
        case contentTypeSelected(State.ContentType)
        case nextTapped
        case backTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .contentTypeSelected(type):
                state.selectedType = type
                return .none
                
            case .nextTapped:
                return .none
                
            case .backTapped:
                return .none
            }
        }
    }
}

struct ContentSelectionView: View {
    let store: StoreOf<ContentSelectionFeature>
    
    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            
            VStack(spacing: 0) {
                // 상단 네비게이션 영역
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
                        height: 15,
                        showStepText: false
                    )
                    
                    Text("4/5")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.leading, 10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // 컨텐츠 영역
                VStack(spacing: 24) {
                    Text("학습 방법을 선택해주세요")
                        .titleSemibold18()
                    
                    Image("pose=front")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 80)
                    
                    // 콘텐츠 선택 버튼들
                    HStack(spacing: 16) {
                        TTECategoryButton(
                            icon: Image("files"),
                            title: "파일 업로드",
                            subtitle: "PDF 파일을\n업로드해요",
                            isSelected: store.selectedType == .fileUpload
                        ) {
                            store.send(.contentTypeSelected(.fileUpload))
                        }
                        
                        TTECategoryButton(
                            icon: Image("files"),
                            title: "카테고리 선택",
                            subtitle: "공부하고 싶은걸\n골라볼게요",
                            isSelected: store.selectedType == .category
                        ) {
                            store.send(.contentTypeSelected(.category))
                        }
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // 하단 다음 버튼
                Button {
                    hideKeyboard()
                    store.send(.nextTapped)
                } label: {
                    Text("다음")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(store.canProceed ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!store.canProceed)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }
}

import ComposableArchitecture
import SwiftUI
import UniformTypeIdentifiers

@Reducer
struct FileUploadFeature {
    @ObservableState
    struct State: Equatable {
        var selectedFileURL: URL?
        var selectedFileName: String?
        var isFileImporterPresented = false
        
        var canProceed: Bool {
            selectedFileURL != nil
        }
    }
    
    enum Action {
        case backTapped
        case fileUploadButtonTapped
        case fileSelected(URL?)
        case fileImporterDismissed
        case nextTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backTapped:
                return .none
                
            case .fileUploadButtonTapped:
                state.isFileImporterPresented = true
                return .none
                
            case let .fileSelected(url):
                state.selectedFileURL = url
                state.selectedFileName = url?.lastPathComponent
                state.isFileImporterPresented = false
                return .none
                
            case .fileImporterDismissed:
                state.isFileImporterPresented = false
                return .none
                
            case .nextTapped:
                // TODO: 다음 화면으로 이동 로직
                return .none
            }
        }
    }
}

struct FileUploadView: View {
    let store: StoreOf<FileUploadFeature>
    
    var body: some View {
        VStack(spacing: 0) {
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
            
            ScrollView {
                VStack(spacing: 0) {
                    Text("원하는 PDF 자료를 넣으세요!")
                        .titleSemibold18()
                    
                    Image("pose=front")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 80)
                        .padding(.top, 20)
                    
                    // 파일 업로드 버튼
                    TTECategoryButton(
                        icon: Image("files"),
                        title: store.selectedFileName ?? "파일 업로드",
                        subtitle: store.selectedFileName != nil
                            ? "파일이 선택되었어요"
                            : "PDF 파일을\n업로드해요",
                        isSelected: store.selectedFileURL != nil,
                        width: 300,
                        height: 200
                    ) {
                        store.send(.fileUploadButtonTapped)
                    }
                    .padding(.top, 56.33)
                    
                    // 선택된 파일 정보 표시 (옵션)
                    if let fileName = store.selectedFileName {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                            Text(fileName)
                                .bodyRegular14()
                                .foregroundColor(._7_A_7_A_7_A)
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 16)
                    }
                }
                .padding(.top, 60)
            }
            .scrollDismissesKeyboard(.interactively)
            
            Spacer()
            
            // 하단 다음 버튼
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
        .fileImporter(
            isPresented: Binding(
                get: { store.isFileImporterPresented },
                set: { if !$0 { store.send(.fileImporterDismissed) } }
            ),
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                store.send(.fileSelected(urls.first))
            case .failure:
                store.send(.fileSelected(nil))
            }
        }
    }
}


struct CategorySelectionView: View {
    let onBack: () -> Void
    
    var body: some View {
        VStack {
            HStack(spacing: 16) {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
            
            Text("카테고리 선택 화면")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
        }
    }
}
