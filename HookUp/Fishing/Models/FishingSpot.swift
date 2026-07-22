import Foundation
import SwiftData
import CoreLocation

@Model
final class FishingSpot {
    var name: String
    var latitude: Double
    var longitude: Double
    var notes: String
    var depthMeters: Double?
    var bottomTypeRaw: String
    var speciesTags: [String]
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \SpotPhoto.spot)
    var photos: [SpotPhoto] = []

    @Relationship(deleteRule: .cascade, inverse: \SpotReview.spot)
    var reviews: [SpotReview] = []

    @Relationship(deleteRule: .nullify, inverse: \FishingTrip.spot)
    var trips: [FishingTrip] = []

    init(
        name: String,
        latitude: Double,
        longitude: Double,
        notes: String = "",
        depthMeters: Double? = nil,
        bottomType: BottomType = .mixed,
        speciesTags: [String] = []
    ) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.notes = notes
        self.depthMeters = depthMeters
        self.bottomTypeRaw = bottomType.rawValue
        self.speciesTags = speciesTags
        self.createdAt = .now
    }

    var coordinate: CLLocationCoordinate2D {
        get { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }

    var bottomType: BottomType {
        get { BottomType(rawValue: bottomTypeRaw) ?? .mixed }
        set { bottomTypeRaw = newValue.rawValue }
    }

    var averageRating: Double {
        guard !reviews.isEmpty else { return 0 }
        return Double(reviews.reduce(0) { $0 + $1.rating }) / Double(reviews.count)
    }
}
