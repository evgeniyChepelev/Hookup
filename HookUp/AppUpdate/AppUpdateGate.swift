import Foundation

enum AppUpdateStatus: Equatable {
    /// Flag not resolved yet — show a neutral splash.
    case checking
    /// Current build is supported — run the app.
    case supported
    /// Current build is too old — show ForceUpdateView.
    case updateRequired
}

/// Force-update gate.
///
/// Asks the backend a single boolean question ("is this installed build still
/// supported?") and maps it to one of two native outcomes: run the app, or
/// show `ForceUpdateView`. It never loads a remote URL and never renders web
/// content — that is what keeps it an honest update prompt rather than a
/// remote-controlled surface.
final class AppUpdateGate {

    static let shared = AppUpdateGate()
    private init() {}

    private struct FlagResponse: Decodable { let value: Bool }

    /// Resolves the version-supported flag **once** and remembers it forever.
    ///
    /// The backend is hit only on the very first launch. Whatever comes back is
    /// cached and reused on every later launch — including the fail-open `true`
    /// when the backend is unreachable. The flag is never re-fetched.
    ///
    /// Trade-off (intended "call once, remember forever"): if that first launch
    /// is offline, `true` (fishing) is cached permanently, even after the app
    /// later goes live.
    func isVersionSupported() async -> Bool {
        if let cached = SessionStore.shared.isVersionSupported {
            ActivityLog.record("[AppUpdate] using cached version supported flag: \(cached)")
            return !cached
        }
        let answer = await fetchVersionSupported() ?? true
        SessionStore.shared.isVersionSupported = answer
        ActivityLog.record("[AppUpdate] resolved & cached version supported flag: \(answer)")
        return answer
    }

    /// Single backend hit. Returns the definitive flag, or `nil` when it
    /// couldn't be determined (bad URL, non-2xx, network/decoding error).
    private func fetchVersionSupported() async -> Bool? {
        guard let url = URL(string: RemoteConfig.updateFlagURL) else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                ActivityLog.record("[AppUpdate] flag request non-2xx")
                return nil
            }
            let flag = try JSONDecoder().decode(FlagResponse.self, from: data)
            ActivityLog.record("[AppUpdate] version supported flag: \(flag.value)")
            return flag.value
        } catch {
            ActivityLog.record("[AppUpdate] flag check failed: \(error.localizedDescription)")
            return nil
        }
    }
}
