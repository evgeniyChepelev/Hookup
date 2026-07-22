import Foundation

final class LiveEventsClient: NSObject {

    static let shared = LiveEventsClient()
    private override init() {}

    var onPortalURLReceived: ((URL) -> Void)?

    private var activeTask: URLSessionDataTask?
    private var buffer = ""
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)

    func openStream() {
        guard activeTask == nil else { return }
        guard let accountId = SessionStore.shared.accountId,
              let regId = SessionStore.shared.deviceRegistrationId else { return }

        var components = URLComponents(string: "\(PlatformAPIClient.baseURL)/sse")!
        components.queryItems = [
            URLQueryItem(name: "user_id", value: accountId),
            URLQueryItem(name: "reg_id", value: regId),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = .infinity

        activeTask = session.dataTask(with: request)
        activeTask?.resume()
        ActivityLog.record("[LiveEvents] Connected")
    }

    func closeStream() {
        activeTask?.cancel()
        activeTask = nil
        buffer = ""
        ActivityLog.record("[LiveEvents] Disconnected")
    }

    private func consume(_ text: String) {
        buffer += text
        let lines = buffer.components(separatedBy: "\n")
        buffer = lines.last ?? ""

        var eventData = ""
        for line in lines.dropLast() {
            if line.hasPrefix("data:") {
                eventData = line.replacingOccurrences(of: "data:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.isEmpty && !eventData.isEmpty {
                dispatchEvent(eventData)
                eventData = ""
            }
        }
    }

    private func dispatchEvent(_ data: String) {
        ActivityLog.record("[LiveEvents] Event: \(data)")
        guard let jsonData = data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else { return }

        if let urlString = json["platform_url"] as? String, let url = URL(string: urlString) {
            ActivityLog.record("[LiveEvents] platform_url received: \(urlString)")
            DispatchQueue.main.async { self.onPortalURLReceived?(url) }
        }
    }
}

extension LiveEventsClient: URLSessionDataDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        consume(text)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error { ActivityLog.record("[LiveEvents] Error: \(error.localizedDescription)") }
        activeTask = nil
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.openStream()
        }
    }
}
