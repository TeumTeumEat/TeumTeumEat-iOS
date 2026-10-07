//
//  NoticeListFeature.swift
//  TeumTeumEat
//

import SwiftUI
import ComposableArchitecture

/// 공지사항 목록 "틈틈잇 소식" (MyPage에서 push로 진입, 무한 스크롤)
@Reducer
struct NoticeListFeature {
    @ObservableState
    struct State: Equatable {
        var notices: [Notice] = []
        /// 마지막으로 불러온 페이지 (0부터 시작, 아직 안 불러왔으면 nil)
        var page: Int?
        var hasNext: Bool = true
        var isLoading: Bool = false
        var errorMessage: String?
        @Presents var detail: NoticeDetailFeature.State?

        static let pageSize = 20
    }

    enum Action {
        case onAppear
        case retryTapped
        case backTapped
        /// 목록 끝 행이 보이면 다음 페이지 조회
        case lastRowAppeared
        case noticeTapped(Notice)
        case noticesLoaded(Result<NoticeSliceResponse, Error>)
        case detail(PresentationAction<NoticeDetailFeature.Action>)
    }

    @Dependency(\.noticeClient) var noticeClient
    @Dependency(\.dismiss) var dismiss
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 상세에서 돌아올 때 다시 조회하지 않도록 첫 진입에만 조회
                guard state.page == nil, !state.isLoading else { return .none }
                return fetchPage(&state, page: 0)

            case .retryTapped:
                return fetchPage(&state, page: (state.page ?? -1) + 1)

            case .backTapped:
                return .run { _ in await dismiss() }

            case .lastRowAppeared:
                // 다음 페이지 조회 실패 후에는 다시 시도 버튼으로만 조회 (스크롤할 때마다 반복 요청 방지)
                guard state.hasNext, !state.isLoading, state.errorMessage == nil,
                      let page = state.page else { return .none }
                return fetchPage(&state, page: page + 1)

            case let .noticeTapped(notice):
                state.detail = NoticeDetailFeature.State(notice: notice)
                // TODO: 읽음 처리 방식(서버 / 기기 저장) 확정 후 반영
                return .none

            case let .noticesLoaded(.success(response)):
                state.isLoading = false
                state.page = response.page
                state.hasNext = response.hasNext
                state.notices.append(contentsOf: response.notices)
                return .none

            case let .noticesLoaded(.failure(error)):
                state.isLoading = false
                state.errorMessage = (error as? APIError)?.overlayMessage ?? "에러가 발생했습니다."
                Log.myPage.error("Failed to load notices: \(error)")
                return .none

            case .detail:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            NoticeDetailFeature()
        }
    }

    private func fetchPage(_ state: inout State, page: Int) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        return .run { send in
            await send(.noticesLoaded(Result {
                try await noticeClient.fetchNotices(page, State.pageSize)
            }))
        }
    }
}

// MARK: - View

struct NoticeListView: View {
    @Bindable var store: StoreOf<NoticeListFeature>

    var body: some View {
        VStack(spacing: 0) {
            NoticeNavigationBar(title: "틈틈잇 소식") {
                store.send(.backTapped)
            }
            content
        }
        .background(Color.gray100.ignoresSafeArea())
        .navigationBarHidden(true)
        .trackScreen(.noticeList)
        .onAppear { store.send(.onAppear) }
        .navigationDestination(
            item: $store.scope(state: \.detail, action: \.detail)
        ) { detailStore in
            NoticeDetailView(store: detailStore)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.notices.isEmpty {
            if let errorMessage = store.errorMessage {
                InlineErrorView(message: errorMessage) {
                    store.send(.retryTapped)
                }
            } else if store.isLoading || store.page == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("등록된 소식이 없어요")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray500)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.notices) { notice in
                        Button {
                            store.send(.noticeTapped(notice))
                        } label: {
                            NoticeRow(notice: notice)
                        }
                        .onAppear {
                            if notice.id == store.notices.last?.id {
                                store.send(.lastRowAppeared)
                            }
                        }
                        Divider()
                    }
                }
                .background(Color.white)

                footer
            }
        }
    }

    /// 다음 페이지 조회 중 / 실패
    @ViewBuilder
    private var footer: some View {
        if store.isLoading {
            ProgressView()
                .padding(.vertical, 20)
        } else if store.errorMessage != nil {
            Button("다시 시도") {
                store.send(.retryTapped)
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.blue500)
            .padding(.vertical, 20)
        }
    }
}

private struct NoticeRow: View {
    let notice: Notice
    // TODO: 읽음 처리 방식 확정 후 안 읽은 공지에 빨간 점 표시
    var isUnread: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(notice.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                Text(notice.dateText)
                    .font(.system(size: 13))
                    .foregroundColor(.gray500)
            }
            Spacer()
            if isUnread {
                Circle()
                    .fill(Color.red500)
                    .frame(width: 6, height: 6)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
    }
}

/// 공지 목록 / 상세 공통 상단 바
struct NoticeNavigationBar: View {
    let title: String
    let onBackTapped: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBackTapped) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                }

                Spacer()

                Text(title)
                    .titleSemibold20()
                    .foregroundStyle(.black)

                Spacer()

                // TODO: 시안의 i 버튼 동작 확정 후 추가 (지금은 제목 가운데 정렬용 자리)
                Image(systemName: "chevron.left")
                    .font(.system(size: 20))
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()
        }
        .background(Color.white)
    }
}

#Preview {
    NavigationStack {
        NoticeListView(
            store: Store(initialState: NoticeListFeature.State()) {
                NoticeListFeature()
            }
        )
    }
}
