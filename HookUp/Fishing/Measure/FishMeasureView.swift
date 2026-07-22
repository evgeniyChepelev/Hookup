import SwiftUI
import UIKit
import PhotosUI
import SwiftData

/// Photo-based catch measurement: auto-detects the fish silhouette (Vision),
/// lets the angler calibrate scale against a reference object, then estimates
/// length and weight — both of which can also be typed in by hand — and
/// saves the result as a Catch. Also shows a history of everything measured.
struct FishMeasureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Catch.caughtAt, order: .reverse) private var allCatches: [Catch]

    var trip: FishingTrip? = nil
    var onSaved: ((Catch) -> Void)? = nil

    @State private var selectedImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showCamera = false

    @State private var fishStart: CGPoint = .zero
    @State private var fishEnd: CGPoint = .zero
    @State private var referenceStart: CGPoint = .zero
    @State private var referenceEnd: CGPoint = .zero
    @State private var autoDetection: FishMaskDetector.DetectionResult?
    @State private var isDetecting = false

    @State private var referenceLengthTag: String = "8.56"
    @State private var referenceLengthCm: Double = 8.56
    @State private var selectedSpeciesName: String = FishSpeciesCatalog.all.first?.name ?? "Other"
    @State private var notes: String = ""

    /// Manual overrides — nil until the angler types a value, at which point
    /// it wins over the photo-calibrated estimate.
    @State private var manualLengthCm: Double?
    @State private var manualWeightGrams: Double?

    /// Photo-calibrated estimate, from the drag handles.
    private var estimatedLengthCm: Double? {
        guard fishStart != .zero, fishEnd != .zero, referenceStart != .zero, referenceEnd != .zero else { return nil }
        return PhotoMeasurementCalculator.lengthCm(
            fishStart: fishStart, fishEnd: fishEnd,
            referenceStart: referenceStart, referenceEnd: referenceEnd,
            referenceLengthCm: referenceLengthCm
        )
    }

    private var finalLengthCm: Double? { manualLengthCm ?? estimatedLengthCm }

    private var estimatedWeightGrams: Double? {
        guard let length = finalLengthCm else { return nil }
        return LengthWeightEstimator.estimatedWeightGrams(speciesName: selectedSpeciesName, lengthCm: length)
    }

    private var finalWeightGrams: Double? { manualWeightGrams ?? estimatedWeightGrams }

    private var lengthFieldBinding: Binding<String> {
        Binding(
            get: { finalLengthCm.map { String(format: "%.1f", $0) } ?? "" },
            set: { manualLengthCm = Double($0.replacingOccurrences(of: ",", with: ".")) }
        )
    }

    private var weightFieldBinding: Binding<String> {
        Binding(
            get: { finalWeightGrams.map { String(format: "%.0f", $0) } ?? "" },
            set: { manualWeightGrams = Double($0.replacingOccurrences(of: ",", with: ".")) }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if let image = selectedImage {
                        VStack(alignment: .leading, spacing: 8) {
                            MeasurementCanvasView(
                                image: image,
                                fishStart: $fishStart,
                                fishEnd: $fishEnd,
                                referenceStart: $referenceStart,
                                referenceEnd: $referenceEnd,
                                autoDetected: autoDetection
                            )
                            .frame(height: 360)
                            .background(Color.black.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            if isDetecting {
                                Label("Detecting fish outline…", systemImage: "wand.and.stars")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Yellow line = fish (nose-to-tail), blue line = reference object. Drag the points if needed.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        referenceSection
                        resultSection
                        speciesSection
                    } else {
                        photoPickerSection
                        historySection
                    }
                }
                .padding()
            }
            .fishingBackground()
            .navigationTitle("Measure Catch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if selectedImage != nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: cancelMeasurement)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveCatch() }
                            .disabled(finalLengthCm == nil)
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView { image in
                    selectedImage = image
                    runDetection(on: image)
                }
                .ignoresSafeArea()
            }
            .onChange(of: photosPickerItem) { _, newValue in
                Task {
                    guard let newValue, let data = try? await newValue.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    selectedImage = image
                    runDetection(on: image)
                }
            }
        }
    }

    private var photoPickerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(FishingTheme.lake)
            Text("Photograph the fish next to an object of known size (bank card, banknote, rod) so the app can work out an accurate length and weight. You can also type the length and weight in by hand.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 24)
    }

    private var historySection: some View {
        SectionCard(title: "My Measurements") {
            if allCatches.isEmpty {
                Text("Everything you measure or log will show up here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(allCatches) { catchItem in
                        CatchSummaryRow(catchItem: catchItem)
                        if catchItem.id != allCatches.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var referenceSection: some View {
        SectionCard(title: "Scale Reference") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Line up the blue points with the edges of an object of known length in the photo.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Reference", selection: $referenceLengthTag) {
                    Text("Bank card — 3.37 in").tag("8.56")
                    Text("Banknote — 6.1 in").tag("15.5")
                    Text("Matchbox — 2 in").tag("5")
                    Text("Custom length").tag("custom")
                }
                .onChange(of: referenceLengthTag) { _, newValue in
                    if let value = Double(newValue) {
                        referenceLengthCm = value
                    }
                }

                if referenceLengthTag == "custom" {
                    HStack {
                        Text("Reference length, cm")
                        Spacer()
                        TextField("cm", value: $referenceLengthCm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            }
        }
    }

    private var resultSection: some View {
        SectionCard(title: "Result") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    editableField(title: "Length, cm", text: lengthFieldBinding)
                    editableField(title: "Weight, g", text: weightFieldBinding)
                }
                if manualLengthCm != nil || manualWeightGrams != nil {
                    Button("Reset to photo estimate") {
                        manualLengthCm = nil
                        manualWeightGrams = nil
                    }
                    .font(.caption)
                } else {
                    Text("Auto-estimated from the photo — edit either value to override.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func editableField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("—", text: text)
                .keyboardType(.decimalPad)
                .font(FishingTheme.displayFont(19))
                .foregroundStyle(FishingTheme.deepWater)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(FishingTheme.sand.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var speciesSection: some View {
        SectionCard(title: "Species") {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Species", selection: $selectedSpeciesName) {
                    ForEach(FishSpeciesCatalog.all) { species in
                        Text(species.name).tag(species.name)
                    }
                }
                .pickerStyle(.menu)

                TextField("Notes", text: $notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func runDetection(on image: UIImage) {
        isDetecting = true
        Task.detached(priority: .userInitiated) {
            let result = FishMaskDetector.detectFishAxis(in: image)
            await MainActor.run {
                autoDetection = result
                isDetecting = false
            }
        }
    }

    private func resetMeasurement() {
        fishStart = .zero
        fishEnd = .zero
        referenceStart = .zero
        referenceEnd = .zero
        autoDetection = nil
        isDetecting = false
        manualLengthCm = nil
        manualWeightGrams = nil
        notes = ""
    }

    /// Clears the in-progress photo/measurement. Also calls `dismiss()`, which
    /// closes the screen when it's sheet-presented (e.g. from the trip editor)
    /// and is a harmless no-op when this view is a standalone tab root — in
    /// that case clearing the photo is the only visible way to signal "cancelled".
    private func cancelMeasurement() {
        selectedImage = nil
        photosPickerItem = nil
        resetMeasurement()
        dismiss()
    }

    private func saveCatch() {
        guard let image = selectedImage, let length = finalLengthCm else { return }
        let fileName = FishPhotoStore.save(image)
        let weight = finalWeightGrams
        let newCatch = Catch(species: selectedSpeciesName, lengthCm: length, weightGrams: weight, photoFileName: fileName, notes: notes)

        if let trip {
            newCatch.trip = trip
            trip.catches.append(newCatch)
        } else {
            modelContext.insert(newCatch)
        }
        try? modelContext.save()
        onSaved?(newCatch)

        selectedImage = nil
        photosPickerItem = nil
        resetMeasurement()
        dismiss()
    }
}
