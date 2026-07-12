import Foundation

/// 积分相关服务
enum PointsService {

    /// 获取当前登录用户的积分汇总
    static func fetchBalance() async throws -> PointsBalance {
        let url = APIConfiguration.shared.apiV1URL + "/points/balance"
        let response: PointsBalanceResponse = try await NetworkService.shared.request(url)
        return response.data
    }

    /// 获取当前用户的积分变动明细
    /// - Parameters:
    ///   - page: 页码，默认 1
    ///   - pageSize: 每页条数，默认 20，最大 100
    static func fetchRecords(page: Int = 1, pageSize: Int = 20) async throws -> PointsRecordsData {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/points/records")!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: String(min(pageSize, 100)))
        ]

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        let response: PointsRecordsResponse = try await NetworkService.shared.request(url)
        return response.data
    }

    /// 检查当前用户是否有权限访问某功能
    /// - Parameter featureCode: 功能标识，如 `ai_chat` / `limit_up_ladder`
    static func checkFeaturePermission(featureCode: String) async throws -> PointsFeaturePermission {
        let url = APIConfiguration.shared.apiV1URL + "/points/features/\(featureCode)"
        let response: PointsFeaturePermissionResponse = try await NetworkService.shared.request(url)
        return response.data
    }
}
