//
//  NoticeDetailFeature.swift
//  TeumTeumEat
//

import SwiftUI
import ComposableArchitecture

/// 공지사항 상세 (목록 응답의 본문을 그대로 표시)
@Reducer
struct NoticeDetailFeature {
    @ObservableState
    struct State: Equatable {
        let notice: Notice
    }

    enum Action {
        case backTapped
    }

    @Dependency(\.dismiss) var dismiss
    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .backTapped:
                return .run { _ in await dismiss() }
            }
        }
    }
}

// MARK: - View

// TODO: 상세 시안 받으면 레이아웃 맞추기 (현재는 제목 / 날짜 / 본문 기본 레이아웃)
struct NoticeDetailView: View {
    let store: StoreOf<NoticeDetailFeature>

    var body: some View {
        VStack(spacing: 0) {
            NoticeNavigationBar(title: "틈틈잇 소식") {
                store.send(.backTapped)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(store.notice.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    Text(store.notice.dateText)
                        .font(.system(size: 13))
                        .foregroundColor(.gray500)
                        .padding(.top, 8)

                    Divider()
                        .padding(.vertical, 20)

                    Text(store.notice.content)
                        .font(.system(size: 15))
                        .foregroundColor(.gray900)
                        .lineSpacing(6)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
        .trackScreen(.noticeDetail)
    }
}

#Preview {
    NavigationStack {
        NoticeDetailView(
            store: Store(initialState: NoticeDetailFeature.State(notice: Notice.mocks[0])) {
                NoticeDetailFeature()
            }
        )
    }
}
