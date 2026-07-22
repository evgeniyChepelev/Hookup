import Foundation

enum FishingStatsCalculator {
    static func tripCount(_ trips: [FishingTrip]) -> Int { trips.count }

    static func totalHoursOnWater(_ trips: [FishingTrip]) -> Double {
        trips.reduce(0) { $0 + $1.durationHours }
    }

    static func seasonRecord(_ catches: [Catch], year: Int = Calendar.current.component(.year, from: .now)) -> Catch? {
        catches
            .filter { Calendar.current.component(.year, from: $0.caughtAt) == year }
            .max { ($0.weightGrams ?? 0) < ($1.weightGrams ?? 0) }
    }

    static func personalBests(_ catches: [Catch]) -> [(species: String, best: Catch)] {
        let grouped = Dictionary(grouping: catches, by: \.species)
        return grouped.compactMap { species, items in
            guard let best = items.max(by: { ($0.weightGrams ?? 0) < ($1.weightGrams ?? 0) }) else { return nil }
            return (species, best)
        }
        .sorted { ($0.best.weightGrams ?? 0) > ($1.best.weightGrams ?? 0) }
    }

    static func speciesCount(_ catches: [Catch]) -> Int {
        Set(catches.map(\.species)).count
    }

    static func achievements(trips: [FishingTrip], catches: [Catch]) -> [Achievement] {
        let tripTotal = tripCount(trips)
        let catchTotal = catches.count
        let biggestGrams = catches.compactMap(\.weightGrams).max() ?? 0

        return [
            Achievement(title: "First Trip", systemImage: "figure.fishing", threshold: 1, progress: tripTotal),
            Achievement(title: "10 Trips", systemImage: "figure.fishing", threshold: 10, progress: tripTotal),
            Achievement(title: "50 Trips", systemImage: "figure.fishing", threshold: 50, progress: tripTotal),
            Achievement(title: "First Catch", systemImage: "fish.fill", threshold: 1, progress: catchTotal),
            Achievement(title: "10 Catches", systemImage: "fish.fill", threshold: 10, progress: catchTotal),
            Achievement(title: "100 Catches", systemImage: "fish.fill", threshold: 100, progress: catchTotal),
            Achievement(title: "5+ kg Trophy", systemImage: "trophy.fill", threshold: 5000, progress: Int(biggestGrams)),
            Achievement(title: "10+ kg Trophy", systemImage: "trophy.fill", threshold: 10000, progress: Int(biggestGrams)),
            Achievement(title: "5 Different Species", systemImage: "checklist", threshold: 5, progress: speciesCount(catches))
        ]
    }
}
