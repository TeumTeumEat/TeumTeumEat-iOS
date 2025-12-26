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
        var errorMessage: String?  // ← 추가
        
        var canProceed: Bool {
            selectedFileURL != nil && errorMessage == nil
        }
    }
    
    enum Action {
        case backTapped
        case fileUploadButtonTapped
        case fileSelected(Result<[URL], Error>)
        case fileImporterDismissed
        case dismissError
        case nextTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backTapped:
                return .none
                
            case .fileUploadButtonTapped:
                state.isFileImporterPresented = true
                state.errorMessage = nil  // 에러 초기화
                return .none
                
            case let .fileSelected(result):
                state.isFileImporterPresented = false
                
                switch result {
                case .success(let urls):
                    guard let url = urls.first else {
                        state.errorMessage = "파일을 선택해주세요"
                        return .none
                    }
                    
                    // 파일 크기 체크
                    do {
                        let fileSize = try url.fileSize()
                        let maxSize: Int64 = 50 * 1024 * 1024  // 50MB
                        
                        if fileSize > maxSize {
                            state.errorMessage = "파일 크기는 50MB 이하여야 합니다"
                            state.selectedFileURL = nil
                            state.selectedFileName = nil
                            return .none
                        }
                        
                        // 성공
                        state.selectedFileURL = url
                        state.selectedFileName = url.lastPathComponent
                        state.errorMessage = nil
                        
                    } catch {
                        state.errorMessage = "파일 정보를 읽을 수 없습니다"
                        state.selectedFileURL = nil
                        state.selectedFileName = nil
                    }
                    
                case .failure:
                    state.errorMessage = "파일 선택에 실패했습니다"
                    state.selectedFileURL = nil
                    state.selectedFileName = nil
                }
                
                return .none
                
            case .fileImporterDismissed:
                state.isFileImporterPresented = false
                return .none
                
            case .dismissError:
                state.errorMessage = nil
                return .none
                
            case .nextTapped:
                return .none
            }
        }
    }
}

extension URL {
    func fileSize() throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: self.path)
        return attributes[.size] as? Int64 ?? 0
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
                            : "PDF 파일을\n업로드해요\n(최대 50MB)",
                        isSelected: store.selectedFileURL != nil,
                        width: 300,
                        height: 200
                    ) {
                        store.send(.fileUploadButtonTapped)
                    }
                    .padding(.top, 56.33)
                    
                    // 에러 메시지 표시
                    if let errorMessage = store.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .bodyRegular14()
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // 선택된 파일 정보 표시
                    if let fileName = store.selectedFileName, store.errorMessage == nil {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(fileName)
                                .bodyRegular14()
                                .foregroundColor(._7_A_7_A_7_A)
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
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
            store.send(.fileSelected(result))
        }
        .alert(
            "파일 크기 초과",
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.send(.dismissError) } }
            )
        ) {
            Button("확인") {
                store.send(.dismissError)
            }
        } message: {
            if let errorMessage = store.errorMessage {
                Text(errorMessage)
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
