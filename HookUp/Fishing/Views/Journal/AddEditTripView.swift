import SwiftUI
import SwiftData

struct AddEditTripView: View {
    enum Mode {
        case new
        case edit(FishingTrip)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FishingSpot.name) private var spots: [FishingSpot]

    @State private var workingTrip: FishingTrip?
    @State private var date: Date = .now
    @State private var startTime: Date = .now
    @State private var endTime: Date?
    @State private var hasEndTime = false
    @State private var tackle: String = ""
    @State private var baitInput: String = ""
    @State private var baits: [String] = []
    @State private var weather: WeatherCondition = .sunny
    @State private var temperatureText: String = ""
    @State private var notes: String = ""
    @State private var selectedSpot: FishingSpot?
    @State private var showMeasure = false
    @State private var showQuickAdd = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date & Time") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    Toggle("Set end time", isOn: $hasEndTime)
                    if hasEndTime {
                        DatePicker(
                            "End",
                            selection: Binding(get: { endTime ?? startTime }, set: { endTime = $0 }),
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                Section("Spot") {
                    Picker("Fishing Spot", selection: $selectedSpot) {
                        Text("No spot").tag(FishingSpot?.none)
                        ForEach(spots) { spot in
                            Text(spot.name).tag(Optional(spot))
                        }
                    }
                }

                Section("Tackle & Bait") {
                    TextField("Tackle (e.g. feeder, spinning rod)", text: $tackle)
                    HStack {
                        TextField("Add bait", text: $baitInput)
                        Button("Add", action: addBait)
                            .disabled(baitInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    if !baits.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(baits, id: \.self) { bait in
                                    baitChip(bait)
                                }
                            }
                        }
                    }
                }

                Section("Weather") {
                    Picker("Weather", selection: $weather) {
                        ForEach(WeatherCondition.allCases) { condition in
                            Label(condition.displayName, systemImage: condition.systemImage).tag(condition)
                        }
                    }
                    HStack {
                        Text("Temperature, °C")
                        Spacer()
                        TextField("optional", text: $temperatureText)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                }

                Section("Catches (\(workingTrip?.catches.count ?? 0))") {
                    if let workingTrip {
                        ForEach(workingTrip.catches.sorted(by: { $0.caughtAt > $1.caughtAt })) { catchItem in
                            CatchSummaryRow(catchItem: catchItem, thumbnailSize: 44)
                        }
                        .onDelete { offsets in
                            deleteCatches(from: workingTrip, at: offsets)
                        }
                    }
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
            .navigationTitle(isEditing ? "Edit Trip" : "New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
            .onAppear(perform: setupIfNeeded)
            .sheet(isPresented: $showMeasure) {
                FishMeasureView(trip: workingTrip)
            }
            .sheet(isPresented: $showQuickAdd) {
                if let workingTrip {
                    QuickAddCatchView(trip: workingTrip)
                }
            }
        }
    }

    private func baitChip(_ bait: String) -> some View {
        HStack(spacing: 4) {
            Text(bait)
            Button {
                baits.removeAll { $0 == bait }
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
        }
        .font(.caption)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Color(.tertiarySystemFill))
        .clipShape(Capsule())
    }

    private func addBait() {
        let trimmed = baitInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        baits.append(trimmed)
        baitInput = ""
    }

    private func setupIfNeeded() {
        guard workingTrip == nil else { return }
        switch mode {
        case .edit(let trip):
            workingTrip = trip
            date = trip.date
            startTime = trip.startTime
            if let end = trip.endTime {
                endTime = end
                hasEndTime = true
            }
            tackle = trip.tackle
            baits = trip.baits
            weather = trip.weatherCondition
            temperatureText = trip.temperatureC.map { String($0) } ?? ""
            notes = trip.notes
            selectedSpot = trip.spot
        case .new:
            let trip = FishingTrip()
            modelContext.insert(trip)
            workingTrip = trip
        }
    }

    private func cancel() {
        if case .new = mode, let workingTrip {
            modelContext.delete(workingTrip)
            try? modelContext.save()
        }
        dismiss()
    }

    private func save() {
        guard let workingTrip else {
            dismiss()
            return
        }
        workingTrip.date = date
        workingTrip.startTime = startTime
        workingTrip.endTime = hasEndTime ? (endTime ?? startTime) : nil
        workingTrip.tackle = tackle
        workingTrip.baits = baits
        workingTrip.weatherCondition = weather
        workingTrip.temperatureC = Double(temperatureText.replacingOccurrences(of: ",", with: "."))
        workingTrip.notes = notes
        workingTrip.spot = selectedSpot
        try? modelContext.save()
        dismiss()
    }

    private func deleteCatches(from trip: FishingTrip, at offsets: IndexSet) {
        let sorted = trip.catches.sorted { $0.caughtAt > $1.caughtAt }
        for index in offsets {
            modelContext.delete(sorted[index])
        }
        try? modelContext.save()
    }
}
