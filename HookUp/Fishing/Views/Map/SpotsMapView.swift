import SwiftUI
import MapKit
import SwiftData
import CoreLocation
import Combine

struct SpotsMapView: View {
    @Query(sort: \FishingSpot.createdAt, order: .reverse) private var spots: [FishingSpot]

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var selectedSpot: FishingSpot?
    @State private var pendingCoordinate: CLLocationCoordinate2D?
    @State private var showAddSpotSheet = false
    @StateObject private var locationProvider = SpotLocationProvider()

    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    ForEach(spots) { spot in
                        Annotation(spot.name, coordinate: spot.coordinate) {
                            Button {
                                selectedSpot = spot
                            } label: {
                                Image(systemName: "fish.fill")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(Circle().fill(FishingTheme.lake))
                            }
                        }
                    }
                    UserAnnotation()
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .onMapCameraChange { context in
                    visibleRegion = context.region
                }
                // A plain `.onTapGesture` competes with MKMapView's own pan/tap
                // recognizers and can silently lose that race. `simultaneousGesture`
                // lets our long-press run alongside the map's built-in gestures
                // instead of fighting them for recognition priority.
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.4)
                        .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                        .onEnded { value in
                            guard case .second(true, let drag) = value,
                                  let location = drag?.location,
                                  let coordinate = proxy.convert(location, from: .local) else { return }
                            pendingCoordinate = coordinate
                            showAddSpotSheet = true
                        }
                )
            }
            .overlay(alignment: .top) {
                Label("Long-press the map to drop a pin", systemImage: "hand.point.up.left.fill")
                    .font(.footnote)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 8)
            }
            .navigationTitle("Fishing Spots")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        guard let center = visibleRegion?.center else { return }
                        pendingCoordinate = center
                        showAddSpotSheet = true
                    } label: {
                        Label("Add Spot Here", systemImage: "mappin.and.ellipse")
                    }
                    .disabled(visibleRegion == nil)
                }
            }
            .task {
                locationProvider.requestPermission()
            }
            .sheet(item: $selectedSpot) { spot in
                SpotDetailView(spot: spot)
            }
            .sheet(isPresented: $showAddSpotSheet) {
                if let pendingCoordinate {
                    AddEditSpotView(mode: .new(pendingCoordinate))
                }
            }
        }
    }
}

final class SpotLocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    let objectWillChange = ObservableObjectPublisher()
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
}
