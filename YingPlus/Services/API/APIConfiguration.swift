import Foundation

enum APIEnvironment {
    case development
    case production

    var baseURL: String {
        switch self {
        case .development:
//             return "http://172.17.80.171:8000"
            return "http://127.0.0.1:8000"
        case .production:
            return "https://api.example.com"
        }
    }
}

struct APIConfiguration {
    static let shared = APIConfiguration()

    var environment: APIEnvironment = .development
    var timeout: TimeInterval = 30

    var baseURL: String {
        environment.baseURL
    }
}

extension APIConfiguration {
    /// v1 API 完整前缀
    var apiV1URL: String {
        baseURL + "/api/v1"
    }
}
