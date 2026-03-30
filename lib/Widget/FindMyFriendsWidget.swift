import ActivityKit
import SwiftUI
import WidgetKit

@main
struct FindMyFriendsWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FindMyFriendsLiveActivityAttributes.self) { context in
            LiveActivityLockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.modeIcon)
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(context.state.distance)
                            .font(.caption.weight(.semibold))
                        Text("\(context.state.steps) steps")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.status)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("XP \(context.state.xp)")
                            .font(.caption.weight(.semibold))
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.modeIcon)
                    .font(.caption)
            } compactTrailing: {
                Text(context.state.distance)
                    .font(.caption2)
            } minimal: {
                Image(systemName: context.state.modeIcon)
            }
        }
    }
}

struct LiveActivityLockScreenView: View {
    let state: FindMyFriendsLiveActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: state.modeIcon)
                .font(.title2)
                .foregroundStyle(.white)
                .padding(10)
                .background(Color.black.opacity(0.3), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text("Live move")
                    .font(.headline)
                Text(state.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(state.distance)
                    .font(.headline)
                Text("Steps \(state.steps)  XP \(state.xp)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
    }
}
