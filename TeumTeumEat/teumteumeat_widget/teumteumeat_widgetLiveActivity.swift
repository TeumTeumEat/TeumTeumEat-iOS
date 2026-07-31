//
//  teumteumeat_widgetLiveActivity.swift
//  teumteumeat_widget
//
//  Created by 임재현 on 7/31/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct teumteumeat_widgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct teumteumeat_widgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: teumteumeat_widgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension teumteumeat_widgetAttributes {
    fileprivate static var preview: teumteumeat_widgetAttributes {
        teumteumeat_widgetAttributes(name: "World")
    }
}

extension teumteumeat_widgetAttributes.ContentState {
    fileprivate static var smiley: teumteumeat_widgetAttributes.ContentState {
        teumteumeat_widgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: teumteumeat_widgetAttributes.ContentState {
         teumteumeat_widgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: teumteumeat_widgetAttributes.preview) {
   teumteumeat_widgetLiveActivity()
} contentStates: {
    teumteumeat_widgetAttributes.ContentState.smiley
    teumteumeat_widgetAttributes.ContentState.starEyes
}
