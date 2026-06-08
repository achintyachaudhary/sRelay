import ActivityKit
import Foundation

@MainActor
final class LiveActivityService {
    static let shared = LiveActivityService()

    private var activity: Activity<GoldiumConnectionAttributes>?

    private init() {}

    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func update(isLive: Bool, status: String) {
        if isLive {
            startOrUpdate(status: status)
        } else {
            end()
        }
    }

    private func startOrUpdate(status: String) {
        guard areActivitiesEnabled else { return }

        let state = GoldiumConnectionAttributes.ContentState(status: status, isLive: true)
        let content = ActivityContent(state: state, staleDate: nil)

        if let activity {
            Task { await activity.update(content) }
            return
        }

        let attributes = GoldiumConnectionAttributes(appName: "Goldium")
        activity = try? Activity.request(
            attributes: attributes,
            content: content,
            pushType: nil
        )
    }

    private func end() {
        guard let activity else { return }

        let finalState = GoldiumConnectionAttributes.ContentState(status: "Disconnected", isLive: false)
        let content = ActivityContent(state: finalState, staleDate: nil)

        Task {
            await activity.end(content, dismissalPolicy: .immediate)
        }
        self.activity = nil
    }
}
