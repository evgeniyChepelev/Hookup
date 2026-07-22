import SwiftUI
import SwiftData
import MapKit

struct SpotDetailView: View {
    @Bindable var spot: FishingSpot

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showAddReview = false
    @State private var showEdit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if !spot.photos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(spot.photos) { photo in
                                    if let image = FishPhotoStore.load(photo.fileName) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 160, height: 160)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                    }

                    Map(initialPosition: .region(
                        MKCoordinateRegion(center: spot.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                    )) {
                        Marker(spot.name, coordinate: spot.coordinate)
                    }
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .allowsHitTesting(false)

                    SectionCard(title: "Depth & Bottom") {
                        HStack(spacing: 12) {
                            StatCard(
                                title: "Depth",
                                value: spot.depthMeters.map { String(format: "%.1f m", $0) } ?? "—",
                                systemImage: "arrow.down.to.line"
                            )
                            StatCard(title: "Bottom", value: spot.bottomType.displayName, systemImage: spot.bottomType.systemImage)
                        }
                    }

                    if !spot.speciesTags.isEmpty {
                        SectionCard(title: "Fish Species") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(spot.speciesTags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12).padding(.vertical, 6)
                                            .background(Color(.tertiarySystemFill))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    if !spot.notes.isEmpty {
                        SectionCard(title: "Notes") {
                            Text(spot.notes)
                        }
                    }

                    SectionCard(title: "Reviews (\(spot.reviews.count))") {
                        VStack(alignment: .leading, spacing: 12) {
                            if spot.averageRating > 0 {
                                HStack {
                                    StaticStarRatingView(rating: spot.averageRating)
                                    Text(String(format: "%.1f", spot.averageRating))
                                        .font(.subheadline.bold())
                                }
                            }

                            let sortedReviews = spot.reviews.sorted { $0.createdAt > $1.createdAt }
                            ForEach(sortedReviews) { review in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(review.author).font(.subheadline.bold())
                                        Spacer()
                                        StaticStarRatingView(rating: Double(review.rating))
                                    }
                                    Text(review.comment).font(.subheadline)
                                }
                                if review.id != sortedReviews.last?.id {
                                    Divider()
                                }
                            }

                            Button {
                                showAddReview = true
                            } label: {
                                Label("Write a Review", systemImage: "plus.bubble")
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(spot.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Edit", systemImage: "pencil") { showEdit = true }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            modelContext.delete(spot)
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showAddReview) {
                AddReviewView(spot: spot)
            }
            .sheet(isPresented: $showEdit) {
                AddEditSpotView(mode: .edit(spot))
            }
        }
    }
}
