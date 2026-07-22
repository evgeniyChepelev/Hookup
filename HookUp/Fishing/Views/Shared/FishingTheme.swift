import SwiftUI
import UIKit

/// Shared "deep water at dusk" visual identity for the fishing module —
/// a teal/gold palette distinct from the system default blue, applied via
/// a handful of reused components so every screen inherits it automatically.
enum FishingTheme {
    static let deepWater = adaptive(light: (10, 47, 58), dark: (6, 26, 32))
    static let lake = adaptive(light: (20, 118, 137), dark: (86, 189, 204))
    static let foam = adaptive(light: (233, 245, 242), dark: (22, 40, 42))
    static let sand = adaptive(light: (245, 235, 214), dark: (36, 30, 20))
    static let lureGold = adaptive(light: (191, 129, 21), dark: (230, 168, 68))

    static var cardBackground: Color { foam }

    static func displayFont(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [foam, sand.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private static func adaptive(light: (Int, Int, Int), dark: (Int, Int, Int)) -> Color {
        Color(uiColor: UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat(c.0) / 255, green: CGFloat(c.1) / 255, blue: CGFloat(c.2) / 255, alpha: 1)
        })
    }
}

/// Wordmark used to give the module a distinct identity wherever a plain
/// navigation title would feel generic.
struct FishingBrandMark: View {
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: "fish.fill")
                    .font(.title3)
                    .foregroundStyle(FishingTheme.lureGold)
                Text("Catchbook")
                    .font(FishingTheme.displayFont(24))
                    .foregroundStyle(FishingTheme.deepWater)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Soft water-toned backdrop for the custom (non-List/Form) screens.
struct FishingBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(FishingTheme.backgroundGradient.ignoresSafeArea())
    }
}

extension View {
    func fishingBackground() -> some View {
        modifier(FishingBackground())
    }
}
