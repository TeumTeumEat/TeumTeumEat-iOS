//
//  URL+.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//


import Foundation

extension URL {
    func fileSize() throws -> Int64 {
        print("파일 크기 확인 시작: \(self.lastPathComponent)")
        
        // Security-scoped resource 접근 시작
        let accessing = startAccessingSecurityScopedResource()
        print("Security-scoped 접근: \(accessing ? "성공" : "불필요")")
        
        defer {
            if accessing {
                stopAccessingSecurityScopedResource()
                print("Security-scoped 해제")
            }
        }
        
        // resourceValues 사용 (더 안전)
        do {
            let resourceValues = try resourceValues(forKeys: [.fileSizeKey])
            guard let fileSize = resourceValues.fileSize else {
                print("파일 크기를 가져올 수 없음")
                throw NSError(
                    domain: "FileUpload",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "파일 크기를 확인할 수 없습니다"]
                )
            }
            
            let sizeMB = Double(fileSize) / 1_000_000
            print("파일 크기: \(fileSize) bytes (\(String(format: "%.2f", sizeMB)) MB)")
            
            return Int64(fileSize)
        } catch {
            print("에러 발생: \(error.localizedDescription)")
            throw error
        }
    }
}
