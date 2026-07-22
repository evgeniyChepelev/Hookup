import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = FishingTheme.lake

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            Text(value)
                .font(FishingTheme.displayFont(19))
                .foregroundStyle(FishingTheme.deepWater)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(FishingTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(tint.opacity(0.15), lineWidth: 1)
        )
    }
}
