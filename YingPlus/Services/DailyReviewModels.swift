import Foundation

/// 每日复盘记录
struct DailyReviewItem: Identifiable, Decodable {
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

/// 复盘列表数据
struct DailyReviewListData: Decodable {
    let list: [DailyReviewItem]
    let total: Int
    let page: Int
    let pageSize: Int

    enum CodingKeys: String, CodingKey {
        case list, total, page
        case pageSize = "page_size"
    }
}

private struct DailyReviewListResponse: Decodable {
    let success: Bool
    let data: DailyReviewListData
}

private struct DailyReviewDetailResponse: Decodable {
    let success: Bool
    let data: DailyReviewItem
}

/// 每日复盘服务
enum DailyReviewService {
    /// 获取当前用户今日复盘
    static func fetchTodayReview() async throws -> DailyReviewItem {
        let response: DailyReviewDetailResponse = try await NetworkService.shared.request(
            APIConfiguration.shared.apiV1URL + "/daily-reviews/today"
        )
        return response.data
    }

    /// 获取当前用户历史复盘列表
    static func fetchReviews(page: Int = 1, pageSize: Int = 20) async throws -> DailyReviewListData {
        let response: DailyReviewListResponse = try await NetworkService.shared.request(
            APIConfiguration.shared.apiV1URL + "/daily-reviews?page=\(page)&page_size=\(pageSize)"
        )
        return response.data
    }

    /// 获取复盘详情
    static func fetchReviewDetail(id: Int) async throws -> DailyReviewItem {
        let response: DailyReviewDetailResponse = try await NetworkService.shared.request(
            APIConfiguration.shared.apiV1URL + "/daily-reviews/\(id)"
        )
        return response.data
    }
}
