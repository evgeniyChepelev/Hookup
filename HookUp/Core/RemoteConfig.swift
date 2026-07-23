import Foundation

enum RemoteConfig {
    static let appStoreId = "6793525406"
    static let oneSignalAppId = "ddc66f15-90c7-4026-96af-954efa330db8"
    static let apiHost = "cronix.pro"

    static var restBaseURL: String { "https://\(apiHost)/api/v1" }
    static var socketBaseURL: String { "https://\(apiHost)" }

    /// Force-update flag endpoint. Must return `{ "value": Bool }` where
    /// `true` = installed build supported (run the app) and
    /// `false` = update required (show ForceUpdateView).
    /// Point this at your real backend route.
    static var updateFlagURL: String { "https://\(apiHost)/api/v1/manager/settings/getUpdates" }
}
