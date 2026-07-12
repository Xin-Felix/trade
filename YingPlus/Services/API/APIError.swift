import Foundation

enum APIError: Error, Equatable, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(String)
    case noData
    case unauthorized
    case serverError
    case paymentRequired(
        featureCode: String,
        reason: String,
        requiredPoints: Int,
        requiredTier: String?,
        balance: Int
    )

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "请求地址无效"
        case .invalidResponse:
            return "服务器返回异常"
        case .httpError(let code, let message):
            if let message = message, !message.isEmpty {
                return "请求失败 (\(code)): \(message)"
            }
            return "请求失败，状态码: \(code)"
        case .decodingError(let message):
            return "数据解析失败: \(message)"
        case .noData:
            return "没有返回数据"
        case .unauthorized:
            return "登录已过期，请重新登录"
        case .serverError:
            return "服务器内部错误"
        case .paymentRequired(_, let reason, _, _, _):
            return reason
        }
    }
}
