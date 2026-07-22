import SwiftUI

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(FishingTheme.displayFont(16))
                .foregroundStyle(FishingTheme.deepWater)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(FishingTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(FishingTheme.lake.opacity(0.12), lineWidth: 1)
        )
    }
}
