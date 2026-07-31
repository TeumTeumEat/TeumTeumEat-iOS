//
//  teumteumeat_widget.swift
//  teumteumeat_widget
//
//  Created by 임재현 on 7/31/26.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct TeumTeumEatWidgetView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: SimpleEntry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView()
        case .systemMedium:
            MediumWidgetView()
        default:
            SmallWidgetView()
        }
    }
}

struct SmallWidgetView: View {
    var body: some View {
        VStack {
            Text("Small Widget")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumWidgetView: View {
    var body: some View {
        VStack {
            Text("Medium Widget")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

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

#Preview(as: .systemSmall) {
    teumteumeat_widget()
} timeline: {
    SimpleEntry(date: .now)
}

#Preview(as: .systemMedium) {
    teumteumeat_widget()
} timeline: {
    SimpleEntry(date: .now)
}
