import SwiftUI

/// Compact summary row for a logged catch: thumbnail, species, length/weight, date.
/// Reused by the trip editor, trip detail screen, and the measurement history list.
struct CatchSummaryRow: View {
    let catchItem: Catch
    var thumbnailSize: CGFloat = 48

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 4) {
                Text(catchItem.species).font(.subheadline.bold())
                HStack(spacing: 8) {
                    if let length = catchItem.lengthCm {
                        Text(String(format: "%.1f cm", length))
                    }
                    if let weight = catchItem.weightGrams {
                        Text(weight >= 1000 ? String(format: "%.2f kg", weight / 1000) : String(format: "%.0f g", weight))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Text(catchItem.caughtAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var thumbnail: some View {
        Group {
            if let fileName = catchItem.photoFileName, let image = FishPhotoStore.load(fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    FishingTheme.foam
                    Image(systemName: "fish.fill")
                        .foregroundStyle(FishingTheme.lake)
                }
            }
        }
        .frame(width: thumbnailSize, height: thumbnailSize)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
