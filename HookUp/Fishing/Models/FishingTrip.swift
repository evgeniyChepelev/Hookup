import Foundation
import SwiftData

@Model
final class FishingTrip {
    var date: Date
    var startTime: Date
    var endTime: Date?
    var tackle: String
    var baits: [String]
    var weatherConditionRaw: String
    var temperatureC: Double?
    var notes: String

    var spot: FishingSpot?

    @Relationship(deleteRule: .cascade, inverse: \Catch.trip)
    var catches: [Catch] = []

    init(
        date: Date = .now,
        startTime: Date = .now,
        endTime: Date? = nil,
        tackle: String = "",
        baits: [String] = [],
        weatherCondition: WeatherCondition = .sunny,
        temperatureC: Double? = nil,
        notes: String = "",
        spot: FishingSpot? = nil
    ) {
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.tackle = tackle
        self.baits = baits
        self.weatherConditionRaw = weatherCondition.rawValue
        self.temperatureC = temperatureC
        self.notes = notes
        self.spot = spot
    }

    var weatherCondition: WeatherCondition {
        get { WeatherCondition(rawValue: weatherConditionRaw) ?? .sunny }
        set { weatherConditionRaw = newValue.rawValue }
    }

    var durationHours: Double {
        let end = endTime ?? .now
        return max(0, end.timeIntervalSince(startTime) / 3600)
    }
}
