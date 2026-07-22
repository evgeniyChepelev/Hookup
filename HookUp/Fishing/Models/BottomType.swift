import Foundation

enum BottomType: String, Codable, CaseIterable, Identifiable {
    case sand
    case mud
    case rock
    case weed
    case clay
    case mixed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sand: return "Sand"
        case .mud: return "Mud"
        case .rock: return "Rocky"
        case .weed: return "Weedy"
        case .clay: return "Clay"
        case .mixed: return "Mixed"
        }
    }

    var systemImage: String {
        switch self {
        case .sand: return "circle.dotted"
        case .mud: return "cloud.fog"
        case .rock: return "triangle.fill"
        case .weed: return "leaf.fill"
        case .clay: return "square.fill"
        case .mixed: return "square.on.circle"
        }
    }
}
