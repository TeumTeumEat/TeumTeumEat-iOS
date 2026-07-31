//
//  teumteumeat_widget.swift
//  teumteumeat_widget
//
//  Created by 임재현 on 7/31/26.
//

import WidgetKit
import SwiftUI

private let appGroupID = "group.com.TeumTeumEat"

struct WidgetEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let totalStamps: Int
    let studiedToday: Bool
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), streak: 7, totalStamps: 42, studiedToday: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let entry = makeEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func makeEntry() -> WidgetEntry {
        let defaults = UserDefaults(suiteName: appGroupID)
        let streak = defaults?.integer(forKey: "widget_streak") ?? 0
        let totalStamps = defaults?.integer(forKey: "widget_totalStamps") ?? 0
        let studiedToday = defaults?.bool(forKey: "widget_studiedToday") ?? false
        return WidgetEntry(date: Date(), streak: streak, totalStamps: totalStamps, studiedToday: studiedToday)
    }
}

// MARK: - Main View

struct TeumTeumEatWidgetView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: WidgetEntry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Text("🔥")
                    .font(.system(size: 28))
                Text("\(entry.streak)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
            }
            Text("\(entry.streak)일 연속")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
            Text(entry.studiedToday ? "오늘 완료! 🎉" : "오늘 아직\n안 먹었어요!")
                .font(.system(size: 12))
                .foregroundColor(entry.studiedToday ? .blue : .orange)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.white, for: .widget)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        HStack(spacing: 0) {
            // 왼쪽: 스트릭
            VStack(alignment: .leading, spacing: 6) {
                Text("연속 학습")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 24))
                    Text("\(entry.streak)일")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                }
                Text(entry.studiedToday ? "오늘 공부 완료! 🎉" : "오늘 아직 안 먹었어요! 🍽️")
                    .font(.system(size: 12))
                    .foregroundColor(entry.studiedToday ? .blue : .orange)
            }

            Spacer()

            // 구분선
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1, height: 60)

            Spacer()

            // 오른쪽: 총 도장
            VStack(alignment: .trailing, spacing: 6) {
                Text("총 도장")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                Text("\(entry.totalStamps)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                Text("개")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.white, for: .widget)
    }
}

// MARK: - Widget

struct teumteumeat_widget: Widget {
    let kind: String = "teumteumeat_widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TeumTeumEatWidgetView(entry: entry)
        }
        .configurationDisplayName("틈틈잇")
        .description("틈틈잇 학습 현황을 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    teumteumeat_widget()
} timeline: {
    WidgetEntry(date: .now, streak: 7, totalStamps: 42, studiedToday: true)
    WidgetEntry(date: .now, streak: 7, totalStamps: 42, studiedToday: false)
}

#Preview(as: .systemMedium) {
    teumteumeat_widget()
} timeline: {
    WidgetEntry(date: .now, streak: 7, totalStamps: 42, studiedToday: true)
    WidgetEntry(date: .now, streak: 7, totalStamps: 42, studiedToday: false)
}
