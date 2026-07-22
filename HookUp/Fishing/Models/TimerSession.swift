import Foundation
import SwiftData

@Model
final class TimerSession {
    var startedAt: Date
    var recastIntervalSeconds: Int
    var recastTimestamps: [Date]
    var endedAt: Date?
    var notes: String

    init(startedAt: Date = .now, recastIntervalSeconds: Int = 600, notes: String = "") {
        self.startedAt = startedAt
        self.recastIntervalSeconds = recastIntervalSeconds
        self.recastTimestamps = []
        self.endedAt = nil
        self.notes = notes
    }

    var recastCount: Int { recastTimestamps.count }

    var durationSeconds: TimeInterval {
        let end = endedAt ?? .now
        return max(0, end.timeIntervalSince(startedAt))
    }
}
