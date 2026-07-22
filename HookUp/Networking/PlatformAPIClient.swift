import Foundation

final class PlatformAPIClient {

    static let shared = PlatformAPIClient()
    static let baseURL = RemoteConfig.restBaseURL
    private let baseURL = PlatformAPIClient.baseURL

    private init() {}

    struct DeviceRegistrationRequest: Encodable {
        let device_id: String
        let app_id: String
        let push_permission_status: String
    }

    struct DeviceRegistrationResponse: Decodable {
        let user_id: String
        let reg_id: String
        let user_state: String
        let webview_url: String?
    }

    func registerDevice(_ body: DeviceRegistrationRequest) async throws -> DeviceRegistrationResponse {
        try await post("/users", body: body, auth: nil)
    }

    struct VoipTokenRequest: Encodable {
        let voip_token: String
    }

    func updateVoipToken(accountId: String, token: String, regToken: String) async throws {
        let body = VoipTokenRequest(voip_token: token)
        let _: EmptyResponse = try await patch("/users/\(accountId)/voip", body: body, auth: regToken)
    }

    struct PermissionsRequest: Encodable {
        let push_permission_status: String
    }

    func updatePermissions(accountId: String, pushStatus: String, regToken: String) async throws {
        let body = PermissionsRequest(push_permission_status: pushStatus)
        let _: EmptyResponse = try await patch("/users/\(accountId)/permissions", body: body, auth: regToken)
    }

    struct PushSubscriptionRequest: Encodable {
        let player_id: String
        let onesignal_id: String
        let is_subscribed: Bool
    }

    func updatePushSubscription(accountId: String, onesignalId: String, playerId: String, isSubscribed: Bool, regToken: String) async throws {
        let body = PushSubscriptionRequest(player_id: playerId, onesignal_id: onesignalId, is_subscribed: isSubscribed)
        let _: EmptyResponse = try await patch("/users/\(accountId)/onesignal", body: body, auth: regToken)
    }

    private struct EmptyResponse: Decodable {}

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let request = URLRequest(url: URL(string: baseURL + path)!)
        return try await dispatch(request)
    }

    private func post<B: Encodable, T: Decodable>(_ path: String, body: B, auth: String?) async throws -> T {
        var request = URLRequest(url: URL(string: baseURL + path)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        if let auth { request.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization") }
        return try await dispatch(request)
    }

    private func patch<B: Encodable, T: Decodable>(_ path: String, body: B, auth: String?) async throws -> T {
        var request = URLRequest(url: URL(string: baseURL + path)!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        if let auth { request.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization") }
        return try await dispatch(request)
    }

    private func dispatch<T: Decodable>(_ request: URLRequest) async throws -> T {
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? ""
        if let body = request.httpBody, let bodyStr = String(data: body, encoding: .utf8) {
            ActivityLog.record("[API] \(method) \(url)\nBody: \(bodyStr)")
        } else {
            ActivityLog.record("[API] \(method) \(url)")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as? HTTPURLResponse
        let status = http?.statusCode ?? 0
        let responseStr = String(data: data, encoding: .utf8) ?? "<binary>"
        ActivityLog.record("[API] Response \(status): \(responseStr)")

        guard let http, (200...299).contains(http.statusCode) else {
            throw NSError(
                domain: "PlatformAPIClient",
                code: status,
                userInfo: [NSLocalizedDescriptionKey: responseStr]
            )
        }
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
