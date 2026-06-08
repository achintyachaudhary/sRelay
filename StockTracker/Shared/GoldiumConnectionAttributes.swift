import ActivityKit
import Foundation

struct GoldiumConnectionAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var status: String
        var isLive: Bool
    }

    var appName: String
}
