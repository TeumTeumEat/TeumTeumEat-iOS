//
//  teumteumeat_widget.swift
//  teumteumeat_widget
//
//  Created by 임재현 on 7/31/26.
//

import WidgetKit
import SwiftUI

private let appGroupID = "group.com.TeumTeumEat"
private let widgetBackground = Color(red: 0.918, green: 0.957, blue: 1.0) // EAF4FF

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

// MARK: - Helpers

private func streakText(for streak: Int) -> String {
    switch streak {
    case 0:        return "얼른 시작 틈틈잇"
    case 1...6:    return "시작이 반이다"
    case 7...29:   return "일주일 연속 틈틈잇!"
    case 30...:    return "한 달 연속 틈틈잇!"
    default:       return "얼른 시작 틈틈잇"
    }
}

private func streakImage(for streak: Int) -> String {
    switch streak {
    case 0:        return "Frame 7407"
    case 1...6:    return "Frame 7408"
    case 7...29:   return "Frame 7409"
    case 30...:    return "Frame 7410"
    default:       return "Frame 7407"
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
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 왼쪽: 스트릭 정보
                VStack(alignment: .leading, spacing: 6) {
                    Spacer()

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Image("fire")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(entry.streak == 0 ? .black : Color(red: 0.94, green: 0.27, blue: 0.27))
                            .frame(width: 22, height: 22)
                        Text("\(entry.streak)")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(entry.streak == 0 ? .black : Color(red: 0.94, green: 0.27, blue: 0.27))
                    }

                    Text("일 연속")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.black)

                    Spacer()

                    Text(streakText(for: entry.streak))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.black.opacity(0.6))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 14)
                .padding(.vertical, 14)
                .frame(width: geometry.size.width * 0.55)

                // 오른쪽: 캐릭터
                Image(streakImage(for: entry.streak))
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width * 0.45)
                    .frame(maxHeight: .infinity)
                    .clipped()
            }
        }
        .containerBackground(widgetBackground, for: .widget)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 왼쪽: 정보
                VStack(alignment: .leading, spacing: 0) {
                    // 스트릭
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Image("fire")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(entry.streak == 0 ? .black : Color(red: 0.94, green: 0.27, blue: 0.27))
                            .frame(width: 28, height: 28)
                        Text("\(entry.streak)")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(entry.streak == 0 ? .black : Color(red: 0.94, green: 0.27, blue: 0.27))
                        Text("일 연속")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.leading, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    Spacer()

                    // 문구
                    Text(streakText(for: entry.streak))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Spacer()

                    // 총 도장
                    HStack(spacing: 6) {
                        Text("총 도장")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.17, green: 0.56, blue: 1.0))
                        Image("stamp")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Color(red: 0.17, green: 0.56, blue: 1.0))
                            .frame(width: 16, height: 16)
                        Text("\(entry.totalStamps)개")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0.17, green: 0.56, blue: 1.0))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(Color.white.opacity(0.6))
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.leading, 16)
                .padding(.trailing, 20)
                .padding(.vertical, 16)
                .frame(width: geometry.size.width * 0.55)

                // 오른쪽: 캐릭터
                Image(streakImage(for: entry.streak))
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width * 0.45)
                    .frame(maxHeight: .infinity)
                    .clipped()
            }
        }
        .containerBackground(widgetBackground, for: .widget)
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
    WidgetEntry(date: .now, streak: 0, totalStamps: 0, studiedToday: false)
    WidgetEntry(date: .now, streak: 3, totalStamps: 10, studiedToday: false)
    WidgetEntry(date: .now, streak: 7, totalStamps: 42, studiedToday: true)
    WidgetEntry(date: .now, streak: 30, totalStamps: 80, studiedToday: true)
}

#Preview(as: .systemMedium) {
    teumteumeat_widget()
} timeline: {
    WidgetEntry(date: .now, streak: 0, totalStamps: 0, studiedToday: false)
    WidgetEntry(date: .now, streak: 3, totalStamps: 10, studiedToday: false)
    WidgetEntry(date: .now, streak: 7, totalStamps: 42, studiedToday: true)
    WidgetEntry(date: .now, streak: 30, totalStamps: 80, studiedToday: true)
}
