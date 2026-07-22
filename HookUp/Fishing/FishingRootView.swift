import SwiftUI
import SwiftData

/// Single entry point for the fishing companion module.
/// Self-contained: sets up its own SwiftData store, so it can be dropped in
/// anywhere as `FishingRootView()` with no external wiring required.
struct FishingRootView: View {
    var body: some View {
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
}

#Preview {
    FishingRootView()
}
