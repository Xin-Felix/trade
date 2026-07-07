import Foundation

enum APIEnvironment {
    case development
    case production

    var baseURL: String {
        switch self {
        case .development:
            return "https://api.dev.example.com"
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
