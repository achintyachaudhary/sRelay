import ActivityKit
import SwiftUI
import WidgetKit

struct GoldiumLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GoldiumConnectionAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(context.state.isLive ? Color.green : Color.gray)
                            .frame(width: 10, height: 10)
                        Text("Goldium")
                            .font(.headline)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.isLive ? "Live" : "Offline")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(context.state.isLive ? .green : .secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Circle()
                    .fill(context.state.isLive ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
            } compactTrailing: {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.caption2)
                    .foregroundStyle(context.state.isLive ? .green : .secondary)
            } minimal: {
                Circle()
                    .fill(context.state.isLive ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<GoldiumConnectionAttributes>) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(context.state.isLive ? Color.green : Color.gray)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text("Goldium · \(context.state.isLive ? "Live Feed" : "Offline")")
                    .font(.headline)
                Text(context.state.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
    }
}
