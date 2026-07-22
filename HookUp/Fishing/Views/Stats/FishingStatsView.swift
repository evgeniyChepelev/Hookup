import SwiftUI
import SwiftData

struct FishingStatsView: View {
    @Query private var trips: [FishingTrip]
    @Query private var catches: [Catch]

    private var achievements: [Achievement] {
        FishingStatsCalculator.achievements(trips: trips, catches: catches)
    }

    private var personalBests: [(species: String, best: Catch)] {
        FishingStatsCalculator.personalBests(catches)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    FishingBrandMark(subtitle: "Your season at a glance")
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Trips", value: "\(FishingStatsCalculator.tripCount(trips))", systemImage: "figure.fishing")
                        StatCard(
                            title: "Hours on Water",
                            value: String(format: "%.0f", FishingStatsCalculator.totalHoursOnWater(trips)),
                            systemImage: "clock"
                        )
                        StatCard(title: "Fish Caught", value: "\(catches.count)", systemImage: "fish.fill")
                        StatCard(title: "Season Record", value: seasonRecordText, systemImage: "trophy.fill", tint: FishingTheme.lureGold)
                    }

                    SectionCard(title: "Achievements") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(achievements) { achievement in
                                AchievementBadge(achievement: achievement)
                            }
                        }
                    }

                    trophiesSection
                }
                .padding()
            }
            .fishingBackground()
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var trophiesSection: some View {
        SectionCard(title: "Trophies") {
            if personalBests.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "trophy")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Your biggest catch of each species will be showcased here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(personalBests, id: \.species) { entry in
                        TrophyCard(catchItem: entry.best)
                    }
                }
            }
        }
    }

    private var seasonRecordText: String {
        guard let record = FishingStatsCalculator.seasonRecord(catches), let weight = record.weightGrams else { return "—" }
        return weight >= 1000 ? String(format: "%.2f kg", weight / 1000) : String(format: "%.0f g", weight)
    }
}

private struct AchievementBadge: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: achievement.systemImage)
                .font(.title2)
                .foregroundStyle(achievement.isUnlocked ? .white : .secondary)
                .frame(width: 52, height: 52)
                .background(achievement.isUnlocked ? FishingTheme.lureGold : Color(.tertiarySystemFill))
                .clipShape(Circle())
            Text(achievement.title)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .opacity(achievement.isUnlocked ? 1 : 0.6)
    }
}

private struct TrophyCard: View {
    let catchItem: Catch

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                photo
                Image(systemName: "trophy.fill")
                    .font(.caption)
                    .foregroundStyle(FishingTheme.lureGold)
                    .padding(6)
                    .background(.ultraThinMaterial, in: Circle())
                    .padding(6)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(catchItem.species)
                    .font(.subheadline.bold())
                    .foregroundStyle(FishingTheme.deepWater)
                HStack(spacing: 6) {
                    if let length = catchItem.lengthCm {
                        Text(String(format: "%.1f cm", length))
                    }
                    if let weight = catchItem.weightGrams {
                        Text(weight >= 1000 ? String(format: "%.2f kg", weight / 1000) : String(format: "%.0f g", weight))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Text(catchItem.caughtAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(FishingTheme.lureGold.opacity(0.25), lineWidth: 1)
        )
    }

    private var photo: some View {
        Group {
            if let fileName = catchItem.photoFileName, let image = FishPhotoStore.load(fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    FishingTheme.foam
                    Image(systemName: "fish.fill")
                        .font(.largeTitle)
                        .foregroundStyle(FishingTheme.lake)
                }
            }
        }
        .frame(height: 110)
        .frame(maxWidth: .infinity)
        .clipped()
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16))
    }
}
