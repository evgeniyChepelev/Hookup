import Foundation

/// Allometric length-weight coefficients (W = a * L^b, W in grams, L in cm),
/// approximate values commonly used for freshwater species in fisheries literature.
struct FishSpecies: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let latinName: String
    let systemImage: String
    let weightCoeffA: Double
    let weightCoeffB: Double
}

enum FishSpeciesCatalog {
    static let generic = FishSpecies(
        name: "Other",
        latinName: "",
        systemImage: "fish.fill",
        weightCoeffA: 0.0110,
        weightCoeffB: 3.02
    )

    static let all: [FishSpecies] = [
        FishSpecies(name: "Pike", latinName: "Esox lucius", systemImage: "fish.fill", weightCoeffA: 0.0026, weightCoeffB: 3.18),
        FishSpecies(name: "Zander", latinName: "Sander lucioperca", systemImage: "fish.fill", weightCoeffA: 0.0068, weightCoeffB: 3.07),
        FishSpecies(name: "Perch", latinName: "Perca fluviatilis", systemImage: "fish.fill", weightCoeffA: 0.0126, weightCoeffB: 3.03),
        FishSpecies(name: "Carp", latinName: "Cyprinus carpio", systemImage: "fish.fill", weightCoeffA: 0.0210, weightCoeffB: 3.05),
        FishSpecies(name: "Wild Carp", latinName: "Cyprinus carpio", systemImage: "fish.fill", weightCoeffA: 0.0198, weightCoeffB: 3.06),
        FishSpecies(name: "Bream", latinName: "Abramis brama", systemImage: "fish.fill", weightCoeffA: 0.0250, weightCoeffB: 2.98),
        FishSpecies(name: "Roach", latinName: "Rutilus rutilus", systemImage: "fish.fill", weightCoeffA: 0.0110, weightCoeffB: 3.01),
        FishSpecies(name: "Crucian Carp", latinName: "Carassius carassius", systemImage: "fish.fill", weightCoeffA: 0.0230, weightCoeffB: 3.04),
        FishSpecies(name: "Catfish", latinName: "Silurus glanis", systemImage: "fish.fill", weightCoeffA: 0.0025, weightCoeffB: 3.22),
        FishSpecies(name: "Trout", latinName: "Salmo trutta", systemImage: "fish.fill", weightCoeffA: 0.0090, weightCoeffB: 3.09),
        FishSpecies(name: "Chub", latinName: "Squalius cephalus", systemImage: "fish.fill", weightCoeffA: 0.0095, weightCoeffB: 3.06),
        FishSpecies(name: "Ide", latinName: "Leuciscus idus", systemImage: "fish.fill", weightCoeffA: 0.0105, weightCoeffB: 3.02),
        FishSpecies(name: "Asp", latinName: "Aspius aspius", systemImage: "fish.fill", weightCoeffA: 0.0048, weightCoeffB: 3.12),
        FishSpecies(name: "Silver Carp", latinName: "Hypophthalmichthys molitrix", systemImage: "fish.fill", weightCoeffA: 0.0140, weightCoeffB: 3.00),
        generic
    ]

    static func species(named name: String) -> FishSpecies {
        all.first { $0.name == name } ?? generic
    }
}
