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
        var isAccessingSecurityScope = false
        
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
        case uploadCompleted
        case stopSecurityAccess
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backTapped:
                // 화면 나갈 때 권한 종료
                if state.isAccessingSecurityScope,
                   let url = state.selectedFileURL {
                    url.stopAccessingSecurityScopedResource()
                    state.isAccessingSecurityScope = false
                    print("[FileUpload] 권한 종료 (화면 종료)")
                }
                return .none
                
            case .fileUploadButtonTapped:
                state.isFileImporterPresented = true
                state.errorMessage = nil
                return .none
                
            case let .fileSelected(result):
                print("[FileUpload] 파일 선택됨")
                state.isFileImporterPresented = false
                
                switch result {
                case .success(let urls):
                    guard let url = urls.first else {
                        print("[FileUpload] URL이 없음")
                        state.errorMessage = "파일을 선택해주세요"
                        return .none
                    }
                    
                    print("[FileUpload] 선택된 파일: \(url.lastPathComponent)")
                    
                    // PDF 확장자 검증
                    let fileExtension = url.pathExtension.lowercased()
                    if fileExtension != "pdf" {
                        print("[FileUpload] 잘못된 파일 형식: .\(fileExtension)")
                        state.errorMessage = "PDF 파일만 업로드 가능합니다\n(선택된 파일: .\(fileExtension))"
                        state.selectedFileURL = nil
                        state.selectedFileName = nil
                        return .none
                    }
                    
                    // 로딩 시작
                    state.isLoadingFile = true
                    state.selectedFileURL = nil
                    state.selectedFileName = url.lastPathComponent
                    state.selectedFileSize = nil
                    
                    print("[FileUpload] 파일 검증 시작...")
                    
                    // ⭐️ 1. 권한 획득 및 파일 검증
                    return .run { send in
                        // 보안 범위 접근 시작
                        guard url.startAccessingSecurityScopedResource() else {
                            print("[FileUpload] 권한 획득 실패")
                            await send(.fileValidationFailed("파일 접근 권한이 없습니다"))
                            return
                        }
                        
                        print("[FileUpload] 권한 획득 성공")
                        
                        // ⭐️ 2. standardizedFileURL 사용
                        let standardizedURL = url.standardizedFileURL
                        print("[FileUpload] Standardized URL: \(standardizedURL.path)")
                        
                        do {
                            let fileSize = try standardizedURL.fileSize()
                            let maxSize: Int64 = 50 * 1024 * 1024  // 50MB
                            
                            if fileSize > maxSize {
                                let sizeMB = Double(fileSize) / 1_000_000
                                print("[FileUpload] 용량 초과: \(String(format: "%.2f", sizeMB))MB > 50MB")
                                
                                // 검증 실패 시 권한 종료
                                url.stopAccessingSecurityScopedResource()
                                print("[FileUpload] 권한 종료 (용량 초과)")
                                
                                await send(.fileValidationFailed(
                                    "파일 크기는 50MB 이하여야 합니다\n(선택된 파일: \(String(format: "%.1f", sizeMB))MB)"
                                ))
                            } else {
                                let sizeMB = Double(fileSize) / 1_000_000
                                print("[FileUpload] 검증 성공 - 크기: \(String(format: "%.2f", sizeMB))MB")
                                
                                // ⭐️ standardizedURL 전달 (권한은 유지)
                                await send(.fileValidationCompleted(standardizedURL, fileSize))
                            }
                        } catch {
                            print("[FileUpload] 검증 실패: \(error.localizedDescription)")
                            
                            // 에러 시 권한 종료
                            url.stopAccessingSecurityScopedResource()
                            print("[FileUpload] 권한 종료 (검증 실패)")
                            
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
                state.selectedFileURL = url  // standardizedURL 저장
                state.selectedFileSize = fileSize
                state.errorMessage = nil
                state.isAccessingSecurityScope = true  // ⭐️ 권한 활성 상태
                print("[FileUpload] 권한 유지 중 (업로드 대기)")
                return .none
                
            case let .fileValidationFailed(message):
                print("[FileUpload] 실패 - \(message)")
                state.isLoadingFile = false
                state.selectedFileURL = nil
                state.selectedFileName = nil
                state.selectedFileSize = nil
                state.errorMessage = message
                state.isAccessingSecurityScope = false
                return .none
                
            case .fileImporterDismissed:
                state.isFileImporterPresented = false
                return .none
                
            case .dismissError:
                state.errorMessage = nil
                return .none
                
            case .nextTapped:
                // 여기서 업로드 진행
                guard let fileURL = state.selectedFileURL else {
                    print("[FileUpload] nextTapped - URL 없음")
                    return .none
                }
                
                print("[FileUpload] 업로드 시작: \(fileURL.lastPathComponent)")
                
                return .run { send in
                    // TODO: 실제 업로드 로직
                    // await uploadFile(fileURL)
                    
                    print("[FileUpload] 업로드 완료")
                    await send(.uploadCompleted)
                }
                
            case .uploadCompleted:
                print("[FileUpload] 업로드 완료 처리")
                // ⭐️ 3. 업로드 완료 후 권한 종료
                return .run { send in
                    await send(.stopSecurityAccess)
                }
                
            case .stopSecurityAccess:
                if state.isAccessingSecurityScope,
                   let url = state.selectedFileURL {
                    url.stopAccessingSecurityScopedResource()
                    state.isAccessingSecurityScope = false
                    print("[FileUpload] 권한 종료 (업로드 완료)")
                }
                return .none
            }
        }
    }
}
