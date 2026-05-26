//
//  FileUploadView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem

public struct FileUploadView: View {
    let store: StoreOf<FileUploadFeature>
    var showProgressBar: Bool

    public init(store: StoreOf<FileUploadFeature>, showProgressBar: Bool = true) {
        self.store = store
        self.showProgressBar = showProgressBar
    }
    
    public var body: some View {
        VStack(spacing: 0) {
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
                    Text("파일 업로드")
                        .font(.system(size: 18, weight: .semibold))
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
            }
            .padding(.horizontal, 20)

            ScrollView {
                VStack(spacing: 0) {
                    Image("character_pdf", bundle: .module)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 283)
                        .padding(.horizontal, 32)
                        .padding(.top, 6)

                    // 파일 업로드 버튼
                    TTECategoryButton(
                        icon: Image("files", bundle: .module),
                        title: store.isLoadingFile
                            ? "파일 확인 중..."
                            : (store.selectedFileName ?? "파일 업로드"),
                        subtitle: store.isLoadingFile
                            ? "잠시만 기다려주세요"
                            : (store.selectedFileURL != nil
                                ? "파일이 선택되었어요\n(\(store.fileSizeText ?? ""))"
                                : "50MB 이하 파일만 업로드 가능"),
                        isSelected: store.selectedFileURL != nil,
                        width: nil,
                        height: 200
                    ) {
                        if !store.isLoadingFile {
                            store.send(.fileUploadButtonTapped)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 15)
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
                }
            }
            .scrollDismissesKeyboard(.interactively)

            TTEButton(
                title: store.isLoadingFile ? "파일 확인 중..." : "다음으로",
                size: .largeFull,
                isEnabled: store.canProceed
            ) {
                store.send(.nextTapped)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
        .background(.white)
        .colorScheme(.light)
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
