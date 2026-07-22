import Foundation
import UserNotifications

final class DeviceOnboardingService {

    static let shared = DeviceOnboardingService()
    private init() {}

    func registerIfNeeded() async {
        guard !SessionStore.shared.isDeviceRegistered else { return }

        let body = PlatformAPIClient.DeviceRegistrationRequest(
            device_id: persistentDeviceId(),
            app_id: RemoteConfig.appStoreId,
            push_permission_status: await currentPushPermissionStatus()
        )

        do {
            let response = try await PlatformAPIClient.shared.registerDevice(body)
            SessionStore.shared.accountId = response.user_id
            SessionStore.shared.deviceRegistrationId = response.reg_id
            let url = response.webview_url.flatMap { URL(string: $0) }
            SessionStore.shared.webPortalURL = url
            SessionStore.shared.relaySignalToken = url.flatMap {
                URLComponents(url: $0, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "token" })?.value
            }
            ActivityLog.record("[Onboarding] Registered, account_id: \(response.user_id)")
            ActivityLog.record("[Onboarding] webPortalURL: \(response.webview_url ?? "nil")")
            await flushQueuedVoipToken()
            PushSubscriptionBridge.shared.syncIfReady()
        } catch {
            ActivityLog.record("[Onboarding] Registration failed: \(error)")
        }
    }

    private func flushQueuedVoipToken() async {
        guard
            let accountId = SessionStore.shared.accountId,
            let regId = SessionStore.shared.deviceRegistrationId,
            let tokenString = UserDefaults.standard.string(forKey: "hookup.pending_voip_token")
        else { return }

        UserDefaults.standard.removeObject(forKey: "hookup.pending_voip_token")
        UserDefaults.standard.removeObject(forKey: "hookup.pending_voip_token_data")

        do {
            try await PlatformAPIClient.shared.updateVoipToken(accountId: accountId, token: tokenString, regToken: regId)
            ActivityLog.record("[Onboarding] Queued VoIP token flushed")
        } catch {
            ActivityLog.record("[Onboarding] Failed to flush VoIP token: \(error)")
        }
    }

    private func persistentDeviceId() -> String {
        if let id = UserDefaults.standard.string(forKey: "hookup.device_id") { return id }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: "hookup.device_id")
        return id
    }

    private func currentPushPermissionStatus() async -> String {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return "granted"
        case .denied: return "denied"
        default: return "notDetermined"
        }
    }
}
