//
//  TTEAlertModifier.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import SwiftUI

enum TTEAlertType {
    case single    // 확인 버튼 1개
    case double    // 취소 + 확인 버튼 2개
}


enum TTEAlertButtonStyle {
    case confirm   // 확인
    case cancel    // 취소
}

struct TTEAlertView: View {
    let type: TTEAlertType
    let title: String
    let message: String
    let confirmTitle: String
    let cancelTitle: String?
    let confirmAction: () -> Void
    let cancelAction: (() -> Void)?
    
    // 디자인 옵션
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let titleColor: Color
    let messageColor: Color
    
    init(
        type: TTEAlertType,
        title: String,
        message: String,
        confirmTitle: String = "확인",
        cancelTitle: String? = nil,
        confirmAction: @escaping () -> Void,
        cancelAction: (() -> Void)? = nil,
        backgroundColor: Color = .white,
        cornerRadius: CGFloat = 16,
        titleColor: Color = .black,
        messageColor: Color = Color(hex: "7A7A7A")
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle ?? "취소"
        self.confirmAction = confirmAction
        self.cancelAction = cancelAction
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.titleColor = titleColor
        self.messageColor = messageColor
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Title & Message
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(titleColor)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(messageColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)
            
            buttonSection
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .frame(width: 280)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var buttonSection: some View {
        switch type {
        case .single:
            // 확인 버튼 1개
            Button(action: confirmAction) {
                Text(confirmTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 240, height: 50)
                    .background(Color(hex: "2B8FFF"))
                    .cornerRadius(8)
            }
            
        case .double:
            HStack(spacing: 10) {
                // 취소 버튼
                Button(action: cancelAction ?? {}) {
                    Text(self.cancelTitle ?? "")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "7A7A7A"))
                        .frame(width: 115, height: 50)
                        .background(Color(hex: "F5F5F5"))
                        .cornerRadius(8)
                }
                
                // 확인 버튼
                Button(action: confirmAction) {
                    Text(confirmTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 115, height: 50)
                        .background(Color(hex: "2B8FFF"))
                        .cornerRadius(8)
                }
            }
        }
    }
}



struct TTEAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let type: TTEAlertType
    let title: String
    let message: String
    let confirmTitle: String
    let cancelTitle: String?
    let confirmAction: () -> Void
    let cancelAction: (() -> Void)?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                // 반투명 배경
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {

                    }
                
                // Alert
                TTEAlertView(
                    type: type,
                    title: title,
                    message: message,
                    confirmTitle: confirmTitle,
                    cancelTitle: cancelTitle,
                    confirmAction: {
                        confirmAction()
                        isPresented = false
                    },
                    cancelAction: {
                        cancelAction?()
                        isPresented = false
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
    }
}

extension View {
    func tteAlert(
        isPresented: Binding<Bool>,
        type: TTEAlertType,
        title: String,
        message: String,
        confirmTitle: String = "확인",
        cancelTitle: String? = nil,
        confirmAction: @escaping () -> Void,
        cancelAction: (() -> Void)? = nil
    ) -> some View {
        self.modifier(
            TTEAlertModifier(
                isPresented: isPresented,
                type: type,
                title: title,
                message: message,
                confirmTitle: confirmTitle,
                cancelTitle: cancelTitle,
                confirmAction: confirmAction,
                cancelAction: cancelAction
            )
        )
    }
}

struct AlertTestView: View {
     @State private var showSingleAlert = false
     @State private var showDoubleAlert = false
     
     var body: some View {
         VStack(spacing: 20) {
             Button("Single Button Alert") {
                 showSingleAlert = true
             }
             .padding()
             .background(Color.blue)
             .foregroundColor(.white)
             .cornerRadius(8)
             
             Button("Double Button Alert") {
                 showDoubleAlert = true
             }
             .padding()
             .background(Color.green)
             .foregroundColor(.white)
             .cornerRadius(8)
         }
         .tteAlert(
             isPresented: $showSingleAlert,
             type: .single,
             title: "알림",
             message: "퀴즈를 완료했습니다!",
             confirmAction: {
                 print("확인 클릭")
             }
         )
         .tteAlert(
             isPresented: $showDoubleAlert,
             type: .double,
             title: "삭제 확인",
             message: "정말로 이 퀴즈를\n삭제하시겠습니까?",
             confirmTitle: "삭제",
             cancelTitle: "취소",
             confirmAction: {
                 print("삭제 클릭")
             },
             cancelAction: {
                 print("취소 클릭")
             }
         )
     }
 }
 

struct MyView2: View {
    @State private var showAlert = false
    @State private var showAlert2 = false
    
    @State private var quizAnswer1: QuizAnswer = .none
    @State private var quizAnswer2: QuizAnswer = .none
    
    @State private var multipleChoice1: Int? = nil
    @State private var multipleChoice2: Int? = nil
    @State private var multipleChoice3: Int? = nil
    @State private var multipleChoice4: Int? = nil
    @State private var multipleChoice5: Int? = nil
    
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Button("삭제") {
                        showAlert = true
                    }
                    
                    Button("확인") {
                        showAlert2 = true
                    }
                }
                
                VStack(spacing: 30) {
                    Text("Quiz Card 테스트")
                        .font(.headline)
                    
                    TTEQuizCard(
                        questionNumber: 1,
                        question: "SwiftUI는 선언형 프레임워크이다SwiftUI는 선언형 프레임워크이다SwiftUI는선언형 프레임워크이다SwiftUI선언형 프레임워크이다SwiftUI선언형 프레임워크이다SwiftUI선언형 프레임워크이다SwiftUI",
                        selectedAnswer: $quizAnswer1,
                        onAnswerSelected: { answer in
                            print("Q1 답변: \(answer)")
                        }
                    )
                    .padding(.horizontal, 20)
                    
                    TTEQuizCard(
                        questionNumber: 2,
                        question: "TCA는 단방향 데이터 흐름 아키텍처이다",
                        selectedAnswer: $quizAnswer2
                    )
                    .padding(.horizontal, 20)
                }
                
                VStack(spacing: 30) {
                    // 선택 안함
                    TTEMultipleChoiceCard(
                        questionNumber: 1,
                        question: "Swift는 어떤 타입의 언어인가?",
                        choices: [
                            "정적 타입 언어",
                            "동적 타입 언어",
                            "하이브리드 언어"
                        ],
                        selectedChoice: $multipleChoice1
                    )
                    .padding(.horizontal, 20)
                    
                    TTEMultipleChoiceCard(
                        questionNumber: 2,
                        question: "SwiftUI는 어떤 프레임워크인가?",
                        choices: [
                            "선언형 프레임워크",
                            "명령형 프레임워크",
                            "함수형 프레임워크"
                        ],
                        selectedChoice: $multipleChoice2
                    )
                    .padding(.horizontal, 20)
                    
                    TTEMultipleChoiceCard(
                        questionNumber: 3,
                        question: "TCA의 핵심 구성요소가 아닌 것은?",
                        choices: [
                            "State",
                            "Action",
                            "Protocol"
                        ],
                        selectedChoice: $multipleChoice3
                    )
                    .padding(.horizontal, 20)
                    
                    TTEMultipleChoiceCard(
                        questionNumber: 4,
                        question: "iOS 개발에서 사용하는 IDE는?",
                        choices: [
                            "Visual Studio",
                            "IntelliJ IDEA",
                            "Xcode"
                        ],
                        selectedChoice: $multipleChoice4
                    )
                    .padding(.horizontal, 20)
                    
                    TTEMultipleChoiceCard(
                        questionNumber: 5,
                        question: "TCA(The Composable Architecture)는 Point-Free에서 만든 단방향 데이터 흐름 아키텍처 패턴이다. 다음 중 TCA의 특징이 아닌 것은?",
                        choices: [
                            "예측 가능한 상태 관리",
                            "테스트 용이성",
                            "양방향 데이터 바인딩"
                        ],
                        selectedChoice: $multipleChoice5
                    )
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
        }
        .tteAlert(
            isPresented: $showAlert,
            type: .double,
            title: "삭제 확인",
            message: "정말로 삭제하시겠습니까?",
            confirmTitle: "삭제",
            confirmAction: {
                print("삭제 버튼 누름")
            },
            cancelAction: {
                print("취소 버튼 누름")
            }
        )
        .tteAlert(
            isPresented: $showAlert2,
            type: .single,
            title: "알림사항",
            message: "다시한번 확인해줘",
            confirmAction: {
                print("확인버튼 누름")
            }
        )
    }
}
