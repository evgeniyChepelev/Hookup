import SwiftUI
import SwiftData

struct TripDetailView: View {
    @Bindable var trip: FishingTrip

    @Environment(\.modelContext) private var modelContext
    @State private var showEdit = false
    @State private var showMeasure = false
    @State private var showQuickAdd = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionCard(title: "Overview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(trip.date.formatted(date: .long, time: .omitted), systemImage: "calendar")
                        if let spot = trip.spot {
                            Label(spot.name, systemImage: "mappin.and.ellipse")
                        }
                        Label(trip.weatherCondition.displayName, systemImage: trip.weatherCondition.systemImage)
                        if let temp = trip.temperatureC {
                            Label(String(format: "%.0f°C", temp), systemImage: "thermometer.medium")
                        }
                        Label(String(format: "%.1f h on the water", trip.durationHours), systemImage: "clock")
                    }
                    .font(.subheadline)
                }

                if !trip.tackle.isEmpty || !trip.baits.isEmpty {
                    SectionCard(title: "Tackle & Bait") {
                        VStack(alignment: .leading, spacing: 6) {
                            if !trip.tackle.isEmpty {
                                Text(trip.tackle)
                            }
                            if !trip.baits.isEmpty {
                                Text(trip.baits.joined(separator: ", "))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.subheadline)
                    }
                }

                if !trip.notes.isEmpty {
                    SectionCard(title: "Notes") {
                        Text(trip.notes)
                    }
                }

                SectionCard(title: "Catches (\(trip.catches.count))") {
                    VStack(alignment: .leading, spacing: 12) {
                        if trip.catches.isEmpty {
                            Text("Nothing added yet").foregroundStyle(.secondary)
                        } else {
                            ForEach(trip.catches.sorted(by: { $0.caughtAt > $1.caughtAt })) { catchItem in
                                CatchSummaryRow(catchItem: catchItem, thumbnailSize: 56)
                            }
                        }

                        Divider()

                        Button {
                            showMeasure = true
                        } label: {
                            Label("Measure from Photo", systemImage: "camera.viewfinder")
                        }
                        Button {
                            showQuickAdd = true
                        } label: {
                            Label("Add Manually", systemImage: "plus.circle")
                        }
                    }
                }
            }
            .padding()
        }
        .fishingBackground()
        .navigationTitle(trip.spot?.name ?? "Trip")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            AddEditTripView(mode: .edit(trip))
        }
        .sheet(isPresented: $showMeasure) {
            FishMeasureView(trip: trip)
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddCatchView(trip: trip)
        }
    }
}
