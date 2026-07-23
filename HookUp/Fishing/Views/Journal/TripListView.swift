import SwiftUI
import SwiftData

struct TripListView: View {
    @Query(sort: \FishingTrip.date, order: .reverse) private var trips: [FishingTrip]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddTrip = false

    private var groupedTrips: [(month: String, trips: [FishingTrip])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: trips) { trip in
            calendar.dateInterval(of: .month, for: trip.date)?.start ?? trip.date
        }
        return grouped.keys.sorted(by: >).map { key in
            (month: key.formatted(.dateTime.month(.wide).year()), trips: grouped[key] ?? [])
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    ContentUnavailableView(
                        "No Trips Yet",
                        systemImage: "book.closed",
                        description: Text("Add your first outing to start your fishing journal.")
                    )
                } else {
                    List {
                        ForEach(groupedTrips, id: \.month) { group in
                            Section(group.month) {
                                ForEach(group.trips) { trip in
                                    NavigationLink(value: trip) {
                                        TripRow(trip: trip)
                                    }
                                }
                                .onDelete { offsets in
                                    delete(trips: group.trips, at: offsets)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Fishing Journal")
            .navigationDestination(for: FishingTrip.self) { trip in
                TripDetailView(trip: trip)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddTrip = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fishingSettingsToolbar()
            .sheet(isPresented: $showAddTrip) {
                AddEditTripView(mode: .new)
            }
        }
    }

    private func delete(trips group: [FishingTrip], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(group[index])
        }
        try? modelContext.save()
    }
}

private struct TripRow: View {
    let trip: FishingTrip

    var body: some View {
        HStack {
            Image(systemName: trip.weatherCondition.systemImage)
                .foregroundStyle(.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.spot?.name ?? "No spot")
                    .font(.subheadline.bold())
                Text(trip.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !trip.catches.isEmpty {
                Label("\(trip.catches.count)", systemImage: "fish.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
