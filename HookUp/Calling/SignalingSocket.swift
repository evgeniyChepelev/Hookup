import Foundation
import SocketIO

final class SignalingSocket {

    static let shared = SignalingSocket()
    private init() {}

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var queuedEvents: [(event: String, items: [SocketData])] = []

    var onCallStarted: ((_ callId: String, _ iceServers: [[String: Any]]) -> Void)?
    var onRemoteOffer: ((_ sdp: String) -> Void)?
    var onRemoteIceCandidate: ((_ candidate: [String: Any]) -> Void)?
    var onCallEnded: ((_ callId: String) -> Void)?

    func open(callId: String) {
        guard
            let accountId = SessionStore.shared.accountId,
            let token = SessionStore.shared.relaySignalToken
        else {
            ActivityLog.record("[Signaling] Missing accountId/token — cannot connect")
            return
        }

        close()

        let manager = SocketManager(
            socketURL: URL(string: RemoteConfig.socketBaseURL)!,
            config: [
                .compress,
                .forceWebsockets(true),
                .connectParams(["user_id": accountId, "token": token]),
            ]
        )
        self.manager = manager

        let socket = manager.socket(forNamespace: "/ws/device")
        self.socket = socket

        ActivityLog.record("[Signaling] Connecting to \(RemoteConfig.socketBaseURL) (/ws/device), accountId=\(accountId)")

        socket.on(clientEvent: .connect) { [weak self] _, _ in
            ActivityLog.record("[Signaling] Connected")
            self?.flushQueuedEvents()
        }
        socket.on(clientEvent: .disconnect) { data, _ in
            ActivityLog.record("[Signaling] Disconnected: \(data)")
        }
        socket.on(clientEvent: .error) { data, _ in
            ActivityLog.record("[Signaling] Error: \(data)")
        }

        socket.on("call.started") { [weak self] data, _ in
            guard let payload = data.first as? [String: Any],
                  let callId = payload["call_id"] as? String,
                  let iceServers = payload["ice_servers"] as? [[String: Any]] else { return }
            ActivityLog.record("[Signaling] call.started: \(callId)")
            self?.onCallStarted?(callId, iceServers)
        }

        socket.on("webrtc.offer") { [weak self] data, _ in
            guard let payload = data.first as? [String: Any],
                  let sdp = payload["sdp"] as? String else { return }
            ActivityLog.record("[Signaling] webrtc.offer received")
            self?.onRemoteOffer?(sdp)
        }

        socket.on("webrtc.ice") { [weak self] data, _ in
            guard let payload = data.first as? [String: Any],
                  let candidate = payload["candidate"] as? [String: Any] else { return }
            self?.onRemoteIceCandidate?(candidate)
        }

        socket.on("call.ended") { [weak self] data, _ in
            guard let payload = data.first as? [String: Any],
                  let callId = payload["call_id"] as? String else { return }
            ActivityLog.record("[Signaling] call.ended: \(callId)")
            self?.onCallEnded?(callId)
        }

        socket.connect(withPayload: ["user_id": accountId, "token": token])
    }

    func close() {
        socket?.disconnect()
        socket = nil
        manager = nil
        queuedEvents.removeAll()
    }

    func sendAccept(callId: String) {
        emit("call.accept", ["call_id": callId])
    }

    func sendReject(callId: String) {
        emit("call.reject", ["call_id": callId])
    }

    func sendAnswer(callId: String, sdp: String) {
        emit("webrtc.answer", ["call_id": callId, "sdp": sdp])
    }

    func sendIceCandidate(callId: String, candidate: [String: Any]) {
        emit("webrtc.ice", ["call_id": callId, "candidate": candidate])
    }

    func sendHangup(callId: String) {
        emit("call.hangup", ["call_id": callId])
    }

    private func emit(_ event: String, _ items: SocketData...) {
        guard let socket, socket.status == .connected else {
            queuedEvents.append((event, items))
            return
        }
        socket.emit(event, with: items, completion: nil)
    }

    private func flushQueuedEvents() {
        let queued = queuedEvents
        queuedEvents.removeAll()
        for item in queued {
            socket?.emit(item.event, with: item.items, completion: nil)
        }
    }
}
