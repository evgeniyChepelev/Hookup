import SwiftUI
import SwiftData

struct QuickAddCatchView: View {
    let trip: FishingTrip

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSpeciesName: String = FishSpeciesCatalog.all.first?.name ?? "Other"
    @State private var lengthText: String = ""
    @State private var weightText: String = ""
    @State private var notes: String = ""
    @State private var useAutoWeight = true

    private var lengthValue: Double? {
        Double(lengthText.replacingOccurrences(of: ",", with: "."))
    }

    private var autoWeightGrams: Double? {
        guard let length = lengthValue else { return nil }
        return LengthWeightEstimator.estimatedWeightGrams(speciesName: selectedSpeciesName, lengthCm: length)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Species") {
                    Picker("Species", selection: $selectedSpeciesName) {
                        ForEach(FishSpeciesCatalog.all) { species in
                            Text(species.name).tag(species.name)
                        }
                    }
                }

                Section("Length & Weight") {
                    HStack {
                        Text("Length, cm")
                        Spacer()
                        TextField("cm", text: $lengthText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    Toggle("Estimate weight automatically", isOn: $useAutoWeight)

                    if useAutoWeight {
                        HStack {
                            Text("Weight (est.)")
                            Spacer()
                            Text(autoWeightGrams.map(formattedWeight) ?? "—")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            Text("Weight, g")
                            Spacer()
                            TextField("g", text: $weightText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("Add Catch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(lengthValue == nil && weightText.isEmpty)
                }
            }
        }
    }

    private func save() {
        let weight = useAutoWeight ? autoWeightGrams : Double(weightText.replacingOccurrences(of: ",", with: "."))
        let newCatch = Catch(species: selectedSpeciesName, lengthCm: lengthValue, weightGrams: weight, notes: notes)
        newCatch.trip = trip
        trip.catches.append(newCatch)
        try? modelContext.save()
        dismiss()
    }

    private func formattedWeight(_ grams: Double) -> String {
        grams >= 1000 ? String(format: "%.2f kg", grams / 1000) : String(format: "%.0f g", grams)
    }
}
