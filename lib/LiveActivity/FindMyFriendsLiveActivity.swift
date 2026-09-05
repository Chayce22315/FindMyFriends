import ActivityKit
import SwiftUI
import WidgetKit

@main
struct FindMyFriendsLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        FindMyFriendsLiveActivity()
    }
}

struct FindMyFriendsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FindMyFriendsActivityAttributes.self) { context in
            LiveActivityLockScreenView(context: context)
                .activityBackgroundTint(Color(red: 0.035, green: 0.045, blue: 0.10))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.state.travelMode)
                            .font(.headline.weight(.semibold))
                    } icon: {
                        Image(systemName: travelIcon(context.state.travelMode))
                    }
                    .foregroundStyle(.white)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(context.state.xp) XP")
                            .font(.headline.monospacedDigit().weight(.bold))
                        Text(distanceText(context.state.distanceMeters))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        Image(systemName: context.state.isTracking ? "location.fill" : "location.slash")
                            .foregroundStyle(context.state.isTracking ? .cyan : .secondary)
                        Text(context.state.isTracking ? "live location is on" : "tracking paused")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(context.attributes.startedAt, style: .timer)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: travelIcon(context.state.travelMode))
                    .foregroundStyle(.cyan)
            } compactTrailing: {
                Text("\(context.state.xp)")
                    .font(.caption.monospacedDigit().weight(.bold))
            } minimal: {
                Image(systemName: travelIcon(context.state.travelMode))
                    .foregroundStyle(.cyan)
            }
            .widgetURL(URL(string: "findmyfriends://move"))
            .keylineTint(.cyan)
        }
    }

    private func travelIcon(_ mode: String) -> String {
        switch mode.lowercased() {
        case "walking": return "figure.walk"
        case "cycling": return "bicycle"
        case "rideshare": return "car"
        case "driving": return "car.fill"
        case "flying": return "airplane"
        case "stopped": return "pause.circle.fill"
        default: return "location.fill"
        }
    }

    private func distanceText(_ meters: Double) -> String {
        let miles = meters / 1_609.344
        if miles < 0.1 {
            return "\(Int(meters)) m"
        }
        return String(format: "%.1f mi", miles)
    }
}

private struct LiveActivityLockScreenView: View {
    let context: ActivityViewContext<FindMyFriendsActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.14))
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.cyan)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Find My Friends")
                        .font(.headline.weight(.semibold))
                    Spacer()
                    Text("\(context.state.xp) XP")
                        .font(.subheadline.monospacedDigit().weight(.bold))
                }

                HStack {
                    Text(context.state.isTracking ? context.state.travelMode : "Tracking paused")
                    Spacer()
                    Text(distanceText(context.state.distanceMeters))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
    }

    private var icon: String {
        switch context.state.travelMode.lowercased() {
        case "walking": return "figure.walk"
        case "cycling": return "bicycle"
        case "rideshare": return "car"
        case "driving": return "car.fill"
        case "flying": return "airplane"
        default: return "location.fill"
        }
    }

    private func distanceText(_ meters: Double) -> String {
        let miles = meters / 1_609.344
        return miles < 0.1 ? "\(Int(meters)) m" : String(format: "%.1f mi", miles)
    }
}
