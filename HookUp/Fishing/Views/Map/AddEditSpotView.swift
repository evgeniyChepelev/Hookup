import SwiftUI
import SwiftData
import PhotosUI
import CoreLocation

struct AddEditSpotView: View {
    enum Mode {
        case new(CLLocationCoordinate2D)
        case edit(FishingSpot)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var depthText: String = ""
    @State private var bottomType: BottomType = .mixed
    @State private var selectedSpecies: Set<String> = []
    @State private var photosPickerItems: [PhotosPickerItem] = []
    @State private var pickedImages: [UIImage] = []

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. \"Hole by the bridge\"", text: $name)
                }

                Section("Depth & Bottom") {
                    HStack {
                        Text("Depth, m")
                        Spacer()
                        TextField("optional", text: $depthText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    Picker("Bottom Type", selection: $bottomType) {
                        ForEach(BottomType.allCases) { type in
                            Label(type.displayName, systemImage: type.systemImage).tag(type)
                        }
                    }
                }

                Section("Fish Species") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(FishSpeciesCatalog.all.filter { $0.name != FishSpeciesCatalog.generic.name }) { species in
                                speciesChip(species.name)
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes about this spot", text: $notes, axis: .vertical)
                }

                Section("Photos") {
                    PhotosPicker(selection: $photosPickerItems, matching: .images) {
                        Label("Add Photos", systemImage: "photo.badge.plus")
                    }
                    if !pickedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(pickedImages.indices, id: \.self) { index in
                                    Image(uiImage: pickedImages[index])
                                        .resizable().scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Spot" : "New Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: photosPickerItems) { _, items in
                Task {
                    var images: [UIImage] = []
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                            images.append(image)
                        }
                    }
                    pickedImages = images
                }
            }
            .onAppear(perform: loadEditingValuesIfNeeded)
        }
    }

    private func speciesChip(_ speciesName: String) -> some View {
        let isSelected = selectedSpecies.contains(speciesName)
        return Text(speciesName)
            .font(.subheadline)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(.tertiarySystemFill))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .onTapGesture {
                if isSelected {
                    selectedSpecies.remove(speciesName)
                } else {
                    selectedSpecies.insert(speciesName)
                }
            }
    }

    private func loadEditingValuesIfNeeded() {
        guard case .edit(let spot) = mode else { return }
        name = spot.name
        notes = spot.notes
        depthText = spot.depthMeters.map { String($0) } ?? ""
        bottomType = spot.bottomType
        selectedSpecies = Set(spot.speciesTags)
    }

    private func save() {
        let depth = Double(depthText.replacingOccurrences(of: ",", with: "."))

        switch mode {
        case .edit(let spot):
            spot.name = name
            spot.notes = notes
            spot.depthMeters = depth
            spot.bottomType = bottomType
            spot.speciesTags = Array(selectedSpecies)
            appendPhotos(to: spot)
        case .new(let coordinate):
            let spot = FishingSpot(
                name: name,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                notes: notes,
                depthMeters: depth,
                bottomType: bottomType,
                speciesTags: Array(selectedSpecies)
            )
            modelContext.insert(spot)
            appendPhotos(to: spot)
        }

        try? modelContext.save()
        dismiss()
    }

    private func appendPhotos(to spot: FishingSpot) {
        for image in pickedImages {
            guard let fileName = FishPhotoStore.save(image) else { continue }
            let photo = SpotPhoto(fileName: fileName)
            photo.spot = spot
            spot.photos.append(photo)
        }
    }
}
