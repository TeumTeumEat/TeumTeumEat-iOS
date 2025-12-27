//
//  FileUploadView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

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
                        title: store.isLoadingFile
                            ? "파일 확인 중..."
                            : (store.selectedFileName ?? "파일 업로드"),
                        subtitle: store.isLoadingFile
                            ? "잠시만 기다려주세요"
                            : (store.selectedFileURL != nil
                                ? "파일이 선택되었어요\n(\(store.fileSizeText ?? ""))"
                                : "PDF 파일을\n업로드해요\n(최대 50MB)"),
                        isSelected: store.selectedFileURL != nil,
                        width: 300,
                        height: 200
                    ) {
                        if !store.isLoadingFile {
                            store.send(.fileUploadButtonTapped)
                        }
                    }
                    .padding(.top, 56.33)
                    .overlay(
                        Group {
                            if store.isLoadingFile {
                                ZStack {
                                    Color.white.opacity(0.8)
                                        .cornerRadius(12)
                                    
                                    ProgressView()
                                        .scaleEffect(1.5)
                                }
                            }
                        }
                    )
                    
                    // 에러 메시지 표시
                    if let errorMessage = store.errorMessage {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                            Text(errorMessage)
                                .bodyRegular14()
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // 선택된 파일 정보 표시
                    if store.selectedFileURL != nil,
                       let fileName = store.selectedFileName,
                       store.errorMessage == nil,
                       !store.isLoadingFile {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fileName)
                                    .bodyRegular14()
                                    .foregroundColor(._7_A_7_A_7_A)
                                if let sizeText = store.fileSizeText {
                                    Text(sizeText)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
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
                title: store.isLoadingFile ? "파일 확인 중..." : "다음",
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
    }
}
