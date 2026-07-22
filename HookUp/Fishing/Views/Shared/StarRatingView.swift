import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int
    var maxRating: Int = 5
    var interactive: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundStyle(FishingTheme.lureGold)
                    .onTapGesture {
                        guard interactive else { return }
                        rating = star
                    }
            }
        }
    }
}

struct StaticStarRatingView: View {
    let rating: Double
    var maxRating: Int = 5

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: icon(for: star))
                    .foregroundStyle(FishingTheme.lureGold)
                    .font(.caption)
            }
        }
    }

    private func icon(for star: Int) -> String {
        if Double(star) <= rating.rounded(.down) { return "star.fill" }
        if Double(star) - rating < 1, Double(star) - rating > 0 { return "star.leadinghalf.filled" }
        return "star"
    }
}
