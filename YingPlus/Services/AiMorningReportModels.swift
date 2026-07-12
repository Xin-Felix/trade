import Foundation

/// AI 晨报记录
struct AiMorningReportItem: Identifiable, Decodable {
    let id: Int
    let reportDate: String?
    let status: String
    let summary: String?
    let content: String?
    let errorMessage: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case reportDate = "report_date"
        case status, summary, content
        case errorMessage = "error_message"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// 晨报列表数据
struct AiMorningReportListData: Decodable {
    let list: [AiMorningReportItem]
    let total: Int
    let page: Int
    let pageSize: Int

    enum CodingKeys: String, CodingKey {
        case list, total, page
        case pageSize = "page_size"
    }
}

private struct AiMorningReportListResponse: Decodable {
    let success: Bool
    let data: AiMorningReportListData
}

private struct AiMorningReportDetailResponse: Decodable {
    let success: Bool
    let data: AiMorningReportItem
}

/// AI 晨报服务
enum AiMorningReportService {
    /// 获取今日晨报
    static func fetchTodayReport() async throws -> AiMorningReportItem {
        let response: AiMorningReportDetailResponse = try await NetworkService.shared.request(
            APIConfiguration.shared.apiV1URL + "/ai-morning-reports/today"
        )
        return response.data
    }

    /// 获取历史晨报列表
    static func fetchReports(page: Int = 1, pageSize: Int = 20) async throws -> AiMorningReportListData {
        let response: AiMorningReportListResponse = try await NetworkService.shared.request(
            APIConfiguration.shared.apiV1URL + "/ai-morning-reports?page=\(page)&page_size=\(pageSize)"
        )
        return response.data
    }

    /// 获取最新可用晨报：优先今日，当天无数据则回退到最近一条历史晨报
    static func fetchLatestAvailableReport() async throws -> AiMorningReportItem {
        do {
            let todayReport = try await fetchTodayReport()
            if todayReport.status == "success", todayReport.summary != nil || todayReport.content != nil {
                return todayReport
            }
        } catch {
            // 今日不可用，继续回退到历史
        }

        let history = try await fetchReports(page: 1, pageSize: 5)
        if let latest = history.list.first(where: { $0.status == "success" && ($0.summary != nil || $0.content != nil) }) {
            return latest
        }

        throw APIError.noData
    }
}
