import Foundation

enum DailyQuoteService {
    /// 获取今日每日一言（公开接口，无需登录）
    static func fetchTodayQuote(policy: CachePolicy = .default) async throws -> DailyQuoteData {
        let url = APIConfiguration.shared.apiV1URL + "/daily-quotes/today"
        let key = "daily_quote_\(MarketCalendar.formatTradeDate(MarketCalendar.latestTradeDate()))"
        let response: DailyQuoteResponse = try await APICacheService.shared.fetch(
            key: key,
            policy: policy,
            ttl: .untilNextTradingDay
        ) {
            try await NetworkService.shared.request(url)
        }
        return response.data
    }
}
