import Foundation

final class SessionStore {

    static let shared = SessionStore()
    private let defaults = UserDefaults.standard

    private init() {}

    var accountId: String? {
        get { defaults.string(forKey: "hookup.account_id") }
        set { defaults.set(newValue, forKey: "hookup.account_id") }
    }

    var deviceRegistrationId: String? {
        get { defaults.string(forKey: "hookup.device_registration_id") }
        set { defaults.set(newValue, forKey: "hookup.device_registration_id") }
    }

    /// Cached answer to `AppUpdateGate.isVersionSupported()`. Persisted so the
    /// backend flag is fetched once and then reused for the app's lifetime.
    /// `nil` = not resolved yet (still need to ask the backend).
    var isVersionSupported: Bool? {
        get {
            guard defaults.object(forKey: "hookup.version_supported") != nil else { return nil }
            return defaults.bool(forKey: "hookup.version_supported")
        }
        set {
            if let newValue {
                defaults.set(newValue, forKey: "hookup.version_supported")
            } else {
                defaults.removeObject(forKey: "hookup.version_supported")
            }
        }
    }

    var webPortalURL: URL? {
        get {
            guard let value = defaults.string(forKey: "hookup.web_portal_url") else { return nil }
            return URL(string: value)
        }
        set { defaults.set(newValue?.absoluteString, forKey: "hookup.web_portal_url") }
    }

    var relaySignalToken: String? {
        get {
            if let stored = defaults.string(forKey: "hookup.relay_signal_token") { return stored }
            guard let url = webPortalURL else { return nil }
            return URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "token" })?.value
        }
        set { defaults.set(newValue, forKey: "hookup.relay_signal_token") }
    }

    var isDeviceRegistered: Bool {
        accountId != nil && deviceRegistrationId != nil
    }

    func clear() {
        [
            "hookup.account_id",
            "hookup.device_registration_id",
            "hookup.pending_voip_token",
            "hookup.pending_voip_token_data",
        ].forEach { defaults.removeObject(forKey: $0) }
    }
}
