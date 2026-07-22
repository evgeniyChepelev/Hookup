import Foundation
import SwiftData

@Model
final class Catch {
    var species: String
    var lengthCm: Double?
    var weightGrams: Double?
    var caughtAt: Date
    var photoFileName: String?
    var notes: String

    var trip: FishingTrip?

    init(
        species: String,
        lengthCm: Double? = nil,
        weightGrams: Double? = nil,
        caughtAt: Date = .now,
        photoFileName: String? = nil,
        notes: String = ""
    ) {
        self.species = species
        self.lengthCm = lengthCm
        self.weightGrams = weightGrams
        self.caughtAt = caughtAt
        self.photoFileName = photoFileName
        self.notes = notes
    }
}
