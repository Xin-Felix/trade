import Foundation

// MARK: - 数据模型

/// 市场温度指标
struct MarketPulseIndicators: Decodable {
    let upCount: Int?
    let downCount: Int?
    let amount: Double?
    let amountChangePct: Double?
    let northMoney: Double?
    let limitUpCount: Int?
    let limitDownCount: Int?
    let openLimitCount: Int?
    let maxContinuousBoard: Int?

    enum CodingKeys: String, CodingKey {
        case upCount = "up_count"
        case downCount = "down_count"
        case amount
        case amountChangePct = "amount_change_pct"
        case northMoney = "north_money"
        case limitUpCount = "limit_up_count"
        case limitDownCount = "limit_down_count"
        case openLimitCount = "open_limit_count"
        case maxContinuousBoard = "max_continuous_board"
    }
}

/// 市场温度数据
struct MarketPulseData: Decodable {
    let tradeDate: String?
    let score: Int
    let level: String
    let summary: String?
    let keywords: [String]
    let indicators: MarketPulseIndicators
    let status: String

    enum CodingKeys: String, CodingKey {
        case tradeDate = "trade_date"
        case score, level, summary, keywords, indicators, status
    }
}

private struct MarketPulseResponse: Decodable {
    let success: Bool
    let data: MarketPulseData?
    let message: String?
}

private struct MarketPulseHistoryResponse: Decodable {
    let success: Bool
    let data: [MarketPulseData]
}

// MARK: - 服务

enum MarketPulseService {
    /// 获取最新市场温度
    static func fetchToday() async throws -> MarketPulseData? {
        let response: MarketPulseResponse = try await NetworkService.shared.request(
            APIConfiguration.shared.apiV1URL + "/market-pulse/today"
        )
        return response.data
    }

    /// 获取历史温度趋势
    static func fetchHistory(limit: Int = 30) async throws -> [MarketPulseData] {
        let response: MarketPulseHistoryResponse = try await NetworkService.shared.request(
            APIConfiguration.shared.apiV1URL + "/market-pulse/history?limit=\(limit)"
        )
        return response.data
    }
}
