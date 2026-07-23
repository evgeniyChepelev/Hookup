import SwiftUI
import SwiftData

/// Single entry point for the fishing companion module.
/// Self-contained: sets up its own SwiftData store, so it can be dropped in
/// anywhere as `FishingRootView()` with no external wiring required.
struct FishingRootView: View {
    @AppStorage("hookup.has_completed_onboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                tabs
            } else {
                FishingOnboardingView(onFinish: { hasCompletedOnboarding = true })
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: hasCompletedOnboarding)
        .modelContainer(
            for: [
                FishingSpot.self,
                SpotPhoto.self,
                SpotReview.self,
                FishingTrip.self,
                Catch.self,
                TimerSession.self
            ]
        )
    }

    private var tabs: some View {
        TabView {
            SpotsMapView()
                .tabItem { Label("Map", systemImage: "map.fill") }

            TripListView()
                .tabItem { Label("Journal", systemImage: "book.closed.fill") }

            FishMeasureView()
                .tabItem { Label("Measure", systemImage: "camera.viewfinder") }

            FishingStatsView()
                .tabItem { Label("Stats", systemImage: "trophy.fill") }

            FishingTimerView()
                .tabItem { Label("Timer", systemImage: "timer") }
        }
        .tint(FishingTheme.lake)
        .toolbarBackground(FishingTheme.foam, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    FishingRootView()
}
