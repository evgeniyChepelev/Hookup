import Foundation
import SwiftData

@Model
final class SpotPhoto {
    var fileName: String
    var caption: String
    var createdAt: Date

    var spot: FishingSpot?

    init(fileName: String, caption: String = "") {
        self.fileName = fileName
        self.caption = caption
        self.createdAt = .now
    }
}
