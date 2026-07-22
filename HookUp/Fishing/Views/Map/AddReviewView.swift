import SwiftUI
import SwiftData

struct AddReviewView: View {
    let spot: FishingSpot

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var author: String = ""
    @State private var rating: Int = 5
    @State private var comment: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Rating") {
                    HStack {
                        Spacer()
                        StarRatingView(rating: $rating)
                            .font(.title2)
                        Spacer()
                    }
                }
                Section("Author") {
                    TextField("Name", text: $author)
                }
                Section("Comment") {
                    TextField("How was the fishing?", text: $comment, axis: .vertical)
                }
            }
            .navigationTitle("Spot Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { save() }
                        .disabled(comment.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let review = SpotReview(
            author: author.trimmingCharacters(in: .whitespaces).isEmpty ? "Anonymous" : author,
            rating: rating,
            comment: comment
        )
        review.spot = spot
        spot.reviews.append(review)
        try? modelContext.save()
        dismiss()
    }
}
