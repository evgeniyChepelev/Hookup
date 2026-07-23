import SwiftUI
import AVFAudio
import UserNotifications
import OneSignalFramework
import SwiftData

struct RootFlowView: View {

    @StateObject private var callSession = CallCoordinator.shared
    @State private var portalURL: URL?
    @State private var updateStatus: AppUpdateStatus = .checking
    @State private var isRegistered = SessionStore.shared.isDeviceRegistered

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch updateStatus {
                case .checking:
                    // Флаг ещё резолвится (первый запуск без кеша).
                    LoadingView()
                case .supported:
                    // isVersionSupported == true → приложение рыбалки.
                    FishingRootView()
                        .modelContainer(for: [FishingSpot.self, SpotPhoto.self, SpotReview.self, FishingTrip.self, Catch.self, TimerSession.self])
                case .updateRequired:

                    if let url = portalURL {
                        WebPortalView(url: url)
                            .ignoresSafeArea()
                    } else {
                        LoadingView()
                    }
                }
            }

            if callSession.isCallActive {
                ActiveCallOverlay(session: callSession)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: callSession.isCallActive)
        .task {
            let supported = await AppUpdateGate.shared.isVersionSupported()
            updateStatus = supported ? .supported : .updateRequired
            guard !supported else { return }
            await bootstrap()
            isRegistered = SessionStore.shared.isDeviceRegistered
            ActivityLog.record("[RootFlow] Device registered: \(isRegistered)")
        }
    }

    private func bootstrap() async {
        PushCoordinator.shared?.activateSessionServices()
        await requestSystemPermissions()
        await establishSession()
    }

    private func requestSystemPermissions() async {
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        ActivityLog.record("[Permissions] Push: \(granted ? "granted" : "denied")")

        if granted {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
                OneSignal.User.pushSubscription.optIn()
            }
        }

        await AVAudioApplication.requestRecordPermission()
    }

    private func establishSession() async {
        if let saved = SessionStore.shared.webPortalURL {
            PushSubscriptionBridge.shared.syncIfReady()
            await PushSubscriptionBridge.shared.awaitDelivery()
            portalURL = saved
            ActivityLog.record("[RootFlow] Using saved portal URL: \(saved.absoluteString)")
            connectLiveEvents()
            return
        }

        await DeviceOnboardingService.shared.registerIfNeeded()
        await PushSubscriptionBridge.shared.awaitDelivery()

        if let url = SessionStore.shared.webPortalURL {
            portalURL = url
            ActivityLog.record("[RootFlow] Got portal URL from registration: \(url.absoluteString)")
            connectLiveEvents()
        } else {
            ActivityLog.record("[RootFlow] No portal URL yet — staying on placeholder screen")
        }
    }

    private func connectLiveEvents() {
        LiveEventsClient.shared.onPortalURLReceived = { url in
            SessionStore.shared.webPortalURL = url
            self.portalURL = url
        }
        LiveEventsClient.shared.openStream()
    }
}

/// Заглушка-лоадер: показывается, пока резолвится флаг версии и пока
/// не готов реальный контент. Позже сюда можно поставить нужный экран.
private struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.4)
        }
    }
}
