import Foundation

struct Achievement: Identifiable {
    var id: String { title }
    let title: String
    let systemImage: String
    let threshold: Int
    let progress: Int

    var isUnlocked: Bool { progress >= threshold }

    var progressFraction: Double {
        guard threshold > 0 else { return 1 }
        return min(1, Double(progress) / Double(threshold))
    }
}
