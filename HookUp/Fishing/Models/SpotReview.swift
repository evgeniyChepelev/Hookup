import Foundation
import SwiftData

@Model
final class SpotReview {
    var author: String
    var rating: Int
    var comment: String
    var createdAt: Date

    var spot: FishingSpot?

    init(author: String, rating: Int, comment: String) {
        self.author = author
        self.rating = min(max(rating, 1), 5)
        self.comment = comment
        self.createdAt = .now
    }
}
