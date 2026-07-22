import Foundation
import UIKit
import OneSignalFramework
import UserNotifications

final class PushSubscriptionBridge: NSObject {

    static let shared = PushSubscriptionBridge()
    private(set) var lastSyncSucceeded = false
    private override init() {}

    private let appId = RemoteConfig.oneSignalAppId

    func initializeSDK(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        OneSignal.initialize(appId, withLaunchOptions: launchOptions)
        OneSignal.User.pushSubscription.addObserver(self)
        ActivityLog.record("[PushBridge] SDK initialized")
    }

    func activate() {
        ActivityLog.record("[PushBridge] activate — onesignalId: \(OneSignal.User.onesignalId ?? "nil")")
        ActivityLog.record("[PushBridge] subscriptionId: \(OneSignal.User.pushSubscription.id ?? "nil")")
        ActivityLog.record("[PushBridge] optedIn: \(OneSignal.User.pushSubscription.optedIn)")
        syncIfReady()
    }

    func awaitDelivery(timeout: TimeInterval = 20) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if lastSyncSucceeded { return }
            syncIfReady()
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        ActivityLog.record("[PushBridge] awaitDelivery: timed out after \(timeout)s")
    }

    func syncIfReady() {
        let onesignalId = OneSignal.User.onesignalId
        let playerId = OneSignal.User.pushSubscription.id
        let isSubscribed = OneSignal.User.pushSubscription.optedIn

        guard
            let accountId = SessionStore.shared.accountId,
            let regId = SessionStore.shared.deviceRegistrationId,
            let onesignalId,
            let playerId
        else {
            ActivityLog.record("[PushBridge] Not ready yet — waiting for observer")
            return
        }

        deliverSubscription(accountId: accountId, regId: regId, onesignalId: onesignalId, playerId: playerId, isSubscribed: isSubscribed)
    }

    private func deliverSubscription(accountId: String, regId: String, onesignalId: String, playerId: String, isSubscribed: Bool) {
        Task {
            do {
                try await PlatformAPIClient.shared.updatePushSubscription(
                    accountId: accountId, onesignalId: onesignalId, playerId: playerId,
                    isSubscribed: isSubscribed, regToken: regId
                )
                self.lastSyncSucceeded = true
                ActivityLog.record("[PushBridge] player_id sent: \(playerId)")

                let settings = await UNUserNotificationCenter.current().notificationSettings()
                let pushStatus: String
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral: pushStatus = "granted"
                case .denied: pushStatus = "denied"
                default: pushStatus = "notDetermined"
                }
                try await PlatformAPIClient.shared.updatePermissions(accountId: accountId, pushStatus: pushStatus, regToken: regId)
                ActivityLog.record("[PushBridge] Permissions synced: push=\(pushStatus)")
            } catch {
                ActivityLog.record("[PushBridge] Failed: \(error)")
            }
        }
    }
}

extension PushSubscriptionBridge: OSPushSubscriptionObserver {

    func onPushSubscriptionDidChange(state: OSPushSubscriptionChangedState) {
        ActivityLog.record("[PushBridge] Subscription changed: id=\(state.current.id ?? "nil") optedIn=\(state.current.optedIn)")

        guard
            let accountId = SessionStore.shared.accountId,
            let regId = SessionStore.shared.deviceRegistrationId,
            let onesignalId = OneSignal.User.onesignalId,
            let playerId = state.current.id
        else {
            ActivityLog.record("[PushBridge] Observer fired but device not registered yet — will retry after registration")
            return
        }

        deliverSubscription(accountId: accountId, regId: regId, onesignalId: onesignalId, playerId: playerId, isSubscribed: state.current.optedIn)
    }
}
