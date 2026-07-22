import Foundation
import CoreGraphics

/// Converts on-screen pixel distances into a real fish length using a
/// reference object of known length placed in the same photo.
enum PhotoMeasurementCalculator {
    static func lengthCm(
        fishStart: CGPoint,
        fishEnd: CGPoint,
        referenceStart: CGPoint,
        referenceEnd: CGPoint,
        referenceLengthCm: Double
    ) -> Double? {
        let referencePixels = hypot(referenceEnd.x - referenceStart.x, referenceEnd.y - referenceStart.y)
        guard referencePixels > 1, referenceLengthCm > 0 else { return nil }

        let fishPixels = hypot(fishEnd.x - fishStart.x, fishEnd.y - fishStart.y)
        let cmPerPixel = referenceLengthCm / referencePixels
        return fishPixels * cmPerPixel
    }
}
