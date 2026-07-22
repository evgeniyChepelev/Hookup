import Foundation

enum WeatherCondition: String, Codable, CaseIterable, Identifiable {
    case sunny
    case cloudy
    case overcast
    case rain
    case snow
    case windy
    case fog

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sunny: return "Sunny"
        case .cloudy: return "Partly Cloudy"
        case .overcast: return "Overcast"
        case .rain: return "Rain"
        case .snow: return "Snow"
        case .windy: return "Windy"
        case .fog: return "Fog"
        }
    }

    var systemImage: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.sun.fill"
        case .overcast: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .windy: return "wind"
        case .fog: return "cloud.fog.fill"
        }
    }
}
