import Foundation

extension Notification.Name {
    /// 收到 401 未授权响应时发送，监听方应清除登录态并回到登录页
    static let sessionUnauthorized = Notification.Name("sessionUnauthorized")
}

final class NetworkService {
    static let shared = NetworkService()

    private let session: URLSession
    private var authToken: String?
    private let tokenLock = NSLock()

    init(session: URLSession = .shared) {
        self.session = session
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

        let (data, response) = try await session.data(for: request)

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
        case 500..<600:
            throw APIError.serverError
        default:
            let message = String(data: data, encoding: .utf8)
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

        let (_, response) = try await session.data(for: request)

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
        case 500..<600:
            throw APIError.serverError
        default:
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: nil)
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
