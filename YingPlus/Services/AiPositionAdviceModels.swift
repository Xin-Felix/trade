import Foundation

/// AI 仓位建议记录
struct AiPositionAdviceItem: Identifiable, Decodable {
    let id: Int
    let userId: Int
    let userPublicId: String?
    let userEmail: String?
    let reportDate: String?
    let status: String
    let summary: String?
    let content: String?
    let errorMessage: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userPublicId = "user_public_id"
        case userEmail = "user_email"
        case reportDate = "report_date"
        case status, summary, content
        case errorMessage = "error_message"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// 仓位建议列表数据
struct AiPositionAdviceListData: Decodable {
    let list: [AiPositionAdviceItem]
    let total: Int
    let page: Int
    let pageSize: Int

    enum CodingKeys: String, CodingKey {
        case list, total, page
        case pageSize = "page_size"
    }
}

private struct AiPositionAdviceListResponse: Decodable {
    let success: Bool
    let data: AiPositionAdviceListData
}

private struct AiPositionAdviceDetailResponse: Decodable {
    let success: Bool
    let data: AiPositionAdviceItem
}

private struct AiPositionAdviceOperationResponse: Decodable {
    let success: Bool
    let message: String
}

/// AI 仓位建议服务
enum AiPositionAdviceService {
    /// 获取当前用户今日仓位建议
    static func fetchTodayAdvice() async throws -> AiPositionAdviceItem {
        let response: AiPositionAdviceDetailResponse = try await NetworkService.shared.request(
            APIConfiguration.shared.apiV1URL + "/ai-position-advices/today"
        )
        return response.data
    }

    /// 获取当前用户历史仓位建议列表
    static func fetchAdvices(page: Int = 1, pageSize: Int = 20) async throws -> AiPositionAdviceListData {
        let response: AiPositionAdviceListResponse = try await NetworkService.shared.request(
            APIConfiguration.shared.apiV1URL + "/ai-position-advices?page=\(page)&page_size=\(pageSize)"
        )
        return response.data
    }

    /// 获取仓位建议详情
    static func fetchAdviceDetail(id: Int) async throws -> AiPositionAdviceItem {
        let response: AiPositionAdviceDetailResponse = try await NetworkService.shared.request(
            APIConfiguration.shared.apiV1URL + "/ai-position-advices/\(id)"
        )
        return response.data
    }

    /// 手动触发今日仓位建议生成（积分用户会按日扣减积分）
    static func generateTodayAdvice() async throws -> String {
        let response: AiPositionAdviceOperationResponse = try await NetworkService.shared.request(
            APIConfiguration.shared.apiV1URL + "/ai-position-advices/generate",
            method: .post
        )
        return response.message
    }
}
