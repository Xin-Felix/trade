import Foundation

extension Notification.Name {
    /// 收到 401 未授权响应时发送，监听方应清除登录态并回到登录页
    static let sessionUnauthorized = Notification.Name("sessionUnauthorized")
    /// 收到 402 需要付费/积分时发送，携带 PaymentRequiredInfo
    static let paymentRequired = Notification.Name("paymentRequired")
}

struct PaymentRequiredInfo {
    let featureCode: String
    let reason: String
    let requiredPoints: Int
    let requiredTier: String?
    let balance: Int
}

final class NetworkService {
    static let shared = NetworkService()

    private let session: URLSession
    private var authToken: String?
    private let tokenLock = NSLock()

    private static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 12
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }

    init(session: URLSession? = nil) {
        self.session = session ?? Self.makeSession()
    }

    func setAuthToken(_ token: String?) {
        tokenLock.lock()
        defer { tokenLock.unlock() }
        authToken = token
    }

    func getAuthToken() -> String? {
        tokenLock.lock()
        defer { tokenLock.unlock() }
        return authToken
    }

    func request<T: Decodable>(
        _ urlString: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = APIConfiguration.shared.timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CancellationError()
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            break
        case 401:
            setAuthToken(nil)
            NotificationCenter.default.post(name: .sessionUnauthorized, object: nil)
            throw APIError.unauthorized
        case 402:
            let info = parsePaymentRequired(data: data, featureCode: nil)
            NotificationCenter.default.post(name: .paymentRequired, object: info)
            throw APIError.paymentRequired(
                featureCode: info.featureCode,
                reason: info.reason,
                requiredPoints: info.requiredPoints,
                requiredTier: info.requiredTier,
                balance: info.balance
            )
        case 500..<600:
            throw APIError.serverError
        default:
            let message = parseErrorMessage(data: data)
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
        }

        guard !data.isEmpty else {
            throw APIError.noData
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    func requestVoid(
        _ urlString: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        headers: [String: String] = [:]
    ) async throws {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = APIConfiguration.shared.timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (_, response): (Data, URLResponse)
        do {
            (_, response) = try await session.data(for: request)
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CancellationError()
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 401:
            setAuthToken(nil)
            NotificationCenter.default.post(name: .sessionUnauthorized, object: nil)
            throw APIError.unauthorized
        case 402:
            let info = parsePaymentRequired(data: Data(), featureCode: nil)
            NotificationCenter.default.post(name: .paymentRequired, object: info)
            throw APIError.paymentRequired(
                featureCode: info.featureCode,
                reason: info.reason,
                requiredPoints: info.requiredPoints,
                requiredTier: info.requiredTier,
                balance: info.balance
            )
        case 500..<600:
            throw APIError.serverError
        default:
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: nil)
        }
    }
    private func parsePaymentRequired(data: Data, featureCode: String?) -> PaymentRequiredInfo {
        let defaultInfo = PaymentRequiredInfo(
            featureCode: featureCode ?? "",
            reason: "该功能需要积分或会员权限",
            requiredPoints: 0,
            requiredTier: nil,
            balance: 0
        )

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let detail = json["detail"] as? [String: Any] else {
            return defaultInfo
        }

        return PaymentRequiredInfo(
            featureCode: (detail["feature_code"] as? String) ?? featureCode ?? "",
            reason: (detail["reason"] as? String) ?? defaultInfo.reason,
            requiredPoints: (detail["required_points"] as? Int) ?? 0,
            requiredTier: detail["required_tier"] as? String,
            balance: (detail["balance"] as? Int) ?? 0
        )
    }

    private func parseErrorMessage(data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return String(data: data, encoding: .utf8)
        }

        let detail = json["detail"]
        if let message = detail as? String {
            return message
        }
        if let dict = detail as? [String: Any] {
            // 优先取 reason，否则返回格式化后的字典字符串
            if let reason = dict["reason"] as? String {
                return reason
            }
            if let prettyData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                return prettyString
            }
        }
        if let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }
        return String(data: data, encoding: .utf8)
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
