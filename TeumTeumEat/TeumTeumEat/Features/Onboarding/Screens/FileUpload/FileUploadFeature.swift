//
//  FileUploadFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture
import UniformTypeIdentifiers

@Reducer
struct FileUploadFeature {
    @ObservableState
    struct State: Equatable {
        var selectedFileURL: URL?
        var selectedFileName: String?
        var selectedFileSize: Int64?
        var isFileImporterPresented = false
        var isLoadingFile = false
        var errorMessage: String?
        
        var canProceed: Bool {
            selectedFileURL != nil && errorMessage == nil && !isLoadingFile
        }

        var fileSizeText: String? {
            guard let size = selectedFileSize else { return nil }
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
    }
    
    enum Action {
        case backTapped
        case fileUploadButtonTapped
        case fileSelected(Result<[URL], Error>)
        case fileValidationCompleted(URL, Int64)
        case fileValidationFailed(String)
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
                state.errorMessage = nil
                return .none
                
            case let .fileSelected(result):
                print("파일 선택됨")
                state.isFileImporterPresented = false
                
                switch result {
                case .success(let urls):
                    guard let url = urls.first else {
                        print("URL이 없음")
                        state.errorMessage = "파일을 선택해주세요"
                        return .none
                    }
                    
                    print("선택된 파일: \(url.lastPathComponent)")
                    
                    // 로딩 시작
                    state.isLoadingFile = true
                    state.selectedFileURL = nil
                    state.selectedFileName = url.lastPathComponent
                    state.selectedFileSize = nil
                    
                    print("파일 검증 시작...")
                    
                    // 비동기로 파일 크기 체크
                    return .run { send in
                        do {
                            let fileSize = try url.fileSize()
                            let maxSize: Int64 = 50 * 1024 * 1024  // 50MB
                            
                            if fileSize > maxSize {
                                let sizeMB = Double(fileSize) / 1_000_000
                                print("[FileUpload] 용량 초과: \(String(format: "%.2f", sizeMB))MB > 50MB")
                                await send(.fileValidationFailed(
                                    "파일 크기는 50MB 이하여야 합니다\n(선택된 파일: \(String(format: "%.1f", sizeMB))MB)"
                                ))
                            } else {
                                print("[FileUpload] 검증 성공")
                                await send(.fileValidationCompleted(url, fileSize))
                            }
                        } catch {
                            print("[FileUpload] 검증 실패: \(error.localizedDescription)")
                            await send(.fileValidationFailed("파일 정보를 읽을 수 없습니다"))
                        }
                    }
                    
                case .failure(let error):
                    print("[FileUpload] 파일 선택 실패: \(error.localizedDescription)")
                    state.errorMessage = "파일 선택에 실패했습니다"
                    state.selectedFileURL = nil
                    state.selectedFileName = nil
                    return .none
                }
                
            case let .fileValidationCompleted(url, fileSize):
                print("[FileUpload] 완료 - 파일: \(url.lastPathComponent), 크기: \(fileSize)")
                state.isLoadingFile = false
                state.selectedFileURL = url
                state.selectedFileSize = fileSize
                state.errorMessage = nil
                return .none
                
            case let .fileValidationFailed(message):
                print("[FileUpload] 실패 - \(message)")
                state.isLoadingFile = false
                state.selectedFileURL = nil
                state.selectedFileName = nil
                state.selectedFileSize = nil
                state.errorMessage = message
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
