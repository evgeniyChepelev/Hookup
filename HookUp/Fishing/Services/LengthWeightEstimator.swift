import Foundation

/// Estimates fish weight from length using the standard allometric
/// length-weight relationship W = a * L^b (W in grams, L in centimeters).
enum LengthWeightEstimator {
    static func estimatedWeightGrams(speciesName: String, lengthCm: Double) -> Double {
        guard lengthCm > 0 else { return 0 }
        let species = FishSpeciesCatalog.species(named: speciesName)
        let weight = species.weightCoeffA * pow(lengthCm, species.weightCoeffB)
        return weight.rounded()
    }
}
