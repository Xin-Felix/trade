import Foundation

enum APIEnvironment {
    case development
    case production

    var baseURL: String {
        switch self {
        case .development:
            // 模拟器直接访问 host 的 localhost；真机调试时改成 Mac 当前局域网 IP
            #if targetEnvironment(simulator)
//            return "http://127.0.0.1:8000"
            #else
//            return "http://172.17.80.171:8000"
            #endif
            return "http://192.168.31.86:8000"
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
