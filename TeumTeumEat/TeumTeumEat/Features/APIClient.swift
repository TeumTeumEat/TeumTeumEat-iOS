//
//  APIClient.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation
import Dependencies

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

struct APIClient {
    
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        // 1. URL 구성
        let baseURL = Config.baseURL
        let fullPath = baseURL + endpoint
        print("API Request: \(method.rawValue) \(fullPath)")
        
        guard let url = URL(string: fullPath) else {
            print("Invalid URL: \(fullPath)")
            throw APIError.invalidURL
        }
        
        // 2. URLRequest 생성
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 3. 인증 토큰 추가
        if requiresAuth {
            guard let token = KeyChainManager.shared.getAccessToken() else {
                print("No access token found in KeyChain")
                throw APIError.noAccessToken
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("Access Token added to request")
        }
        
        // 4. Request Body 추가 (POST, PUT 등)
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
                if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                    print("Request Body: \(bodyString)")
                }
            } catch {
                print("Failed to encode request body: \(error)")
                throw APIError.encodingFailed(error)
            }
        }
        
        // 5. 네트워크 요청
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 6. HTTP 응답 확인
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("HTTP Status: \(httpResponse.statusCode)")
            
            // 7. 응답 데이터 로깅
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response JSON: \(jsonString)")
            }
            
            // 8. 상태 코드별 처리
            switch httpResponse.statusCode {
            case 200...299:
                // 성공 - 데이터 디코딩
                do {
                    let decodedData = try JSONDecoder().decode(T.self, from: data)
                    print("Successfully decoded response")
                    return decodedData
                } catch {
                    print("Decoding Error: \(error)")
                    throw APIError.decodingError(error)
                }
                
            case 400...599:
                // 에러 응답 - 서버 에러 파싱
                do {
                    let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: data)
                    print("Server Error - Code: \(errorResponse.code), Message: \(errorResponse.message)")
                    throw APIError.serverError(
                        code: errorResponse.code,
                        message: errorResponse.message,
                        details: errorResponse.details
                    )
                } catch let decodingError as DecodingError {
                    // 에러 응답 파싱 실패 - HTTP 상태 코드로 폴백
                    print("Failed to decode error response: \(decodingError)")
                    throw APIError.serverError(
                        code: "HTTP-\(httpResponse.statusCode)",
                        message: "서버 오류 (상태 코드: \(httpResponse.statusCode))",
                        details: nil
                    )
                } catch let apiError as APIError {
                    // 이미 APIError인 경우 그대로 throw
                    throw apiError
                }
                
            default:
                // 예상치 못한 상태 코드
                throw APIError.serverError(
                    code: "HTTP-\(httpResponse.statusCode)",
                    message: "예상치 못한 응답 (상태 코드: \(httpResponse.statusCode))",
                    details: nil
                )
            }
            
        } catch let error as APIError {
            // 이미 APIError로 변환된 경우 그대로 throw
            throw error
        } catch {
            // 네트워크 레이어 에러 (연결 실패, 타임아웃 등)
            print("Network Error: \(error)")
            throw APIError.networkError(error)
        }
    }
}

extension APIClient: DependencyKey {
    static let liveValue = APIClient()
}

extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}


extension APIClient {
    func fetchCategories() async throws -> [CategoryResponse] {
        // APIResponse<CategoryData>로 디코딩
        let response: APIResponse<CategoryData> = try await request(
            endpoint: "/api/v1/categories",
            method: .get,
            requiresAuth: true
        )
        
        // 응답 검증
        guard response.code == "OK",
              let categoryData = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        
        print("Categories loaded: \(categoryData.categoryResponses.count) items")
        return categoryData.categoryResponses
    }
}

extension APIClient {
    /// 유저 이름 수정
    func updateUserName(name: String) async throws {
        // APIResponse<EmptyData> 형태로 받기
        let response: APIResponse<EmptyData> = try await request(
            endpoint: "/api/v1/users/name",
            method: .patch,
            body: UpdateUserNameRequest(name: name),
            requiresAuth: true
        )
        
        // 응답 검증
        guard response.code == "OK" else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        print("User name updated successfully: \(name)")
    }
    
    /// 출퇴근 정보 수정
       func updateCommuteInfo(
           startTime: String,
           endTime: String,
           usageTime: Int
       ) async throws {
           let response: APIResponse<EmptyData> = try await request(
               endpoint: "/api/v1/users/commute-info",
               method: .patch,
               body: UpdateCommuteInfoRequest(
                   startTime: startTime,
                   endTime: endTime,
                   usageTime: usageTime
               ),
               requiresAuth: true
           )
           
           guard response.code == "OK" else {
               throw APIError.serverError(
                   code: response.code,
                   message: response.message,
                   details: response.details
               )
           }
           
           print("Commute info updated successfully - Start: \(startTime), End: \(endTime), Usage: \(usageTime)분")
       }
}

extension APIClient {
    /// 목표 생성
      func createGoal(
          type: CreateGoalRequest.GoalType,
          studyPeriod: String,
          difficulty: CreateGoalRequest.Difficulty,
          prompt: String?,
          categoryId: Int?
      ) async throws {
          let response: APIResponse<EmptyData> = try await request(
              endpoint: "/api/v1/goals",
              method: .post,
              body: CreateGoalRequest(
                  type: type,
                  studyPeriod: studyPeriod,
                  difficulty: difficulty,
                  prompt: prompt,
                  categoryId: categoryId
              ),
              requiresAuth: true
          )
          
          guard response.code == "OK" else {
              throw APIError.serverError(
                  code: response.code,
                  message: response.message,
                  details: response.details
              )
          }
          
          print("Goal created successfully - Type: \(type.rawValue), Period: \(studyPeriod)")
      }
    
    /// PDF 문서 등록
     func registerDocument(
         goalId: Int,
         fileName: String,
         fileKey: String
     ) async throws {
         let response: APIResponse<EmptyData> = try await request(
             endpoint: "/api/v1/goals/\(goalId)/documents",
             method: .post,
             body: RegisterDocumentRequest(
                 fileName: fileName,
                 fileKey: fileKey
             ),
             requiresAuth: true
         )
         
         guard response.code == "OK" else {
             throw APIError.serverError(
                 code: response.code,
                 message: response.message,
                 details: response.details
             )
         }
         
         print("Document registered successfully - GoalId: \(goalId), FileName: \(fileName)")
     }
    
    func getPresignedURL(fileName: String) async throws -> PresignedURLData {
         let response: APIResponse<PresignedURLData> = try await request(
             endpoint: "/api/v1/s3/presigned",
             method: .post,
             body: PresignedURLRequest(fileName: fileName),
             requiresAuth: true
         )
         
         guard response.code == "OK",
               let data = response.data else {
             throw APIError.serverError(
                 code: response.code,
                 message: response.message,
                 details: response.details
             )
         }
         
         print("   PresignedURL received for file: \(fileName)")
         print("   URL: \(data.presignedUrl)")
         print("   Key: \(data.key)")
         
         return data
     }
    
    /// S3에 PDF 파일 업로드
    func uploadFileToS3(fileURL: URL, presignedURL: String) async throws {
        guard let url = URL(string: presignedURL) else {
            throw APIError.invalidURL
        }
        
        // 파일 데이터 읽기
        let fileData: Data
        do {
            fileData = try Data(contentsOf: fileURL)
            print("File loaded - Size: \(fileData.count) bytes")
        } catch {
            print("Failed to load file: \(error)")
            throw APIError.networkError(error)
        }
        
        // URLRequest 생성
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/pdf", forHTTPHeaderField: "Content-Type")
        request.httpBody = fileData
        
        print("Uploading file to S3...")
        
        // S3에 업로드
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("S3 Upload Status: \(httpResponse.statusCode)")
            
            // S3는 보통 200 또는 204 반환
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(
                    code: "S3-\(httpResponse.statusCode)",
                    message: "S3 업로드 실패 (상태 코드: \(httpResponse.statusCode))",
                    details: nil
                )
            }
            
            print("File uploaded to S3 successfully")
            
        } catch let error as APIError {
            throw error
        } catch {
            print("S3 Upload Error: \(error)")
            throw APIError.networkError(error)
        }
    }
}
