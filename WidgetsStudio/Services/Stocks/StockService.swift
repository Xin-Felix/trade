import Foundation

enum StockService {
    /// 获取单只股票最新行情
    static func fetchQuote(code: String) async throws -> StockData {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/quote/\(code)"
        return try await NetworkService.shared.request(url)
    }

    /// 获取 K 线数据
    static func fetchKlines(code: String, period: KlinePeriod = .day, limit: Int = 60) async throws -> [KlineData] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/klines/\(code)")!
        components.queryItems = [
            URLQueryItem(name: "period", value: period.rawValue),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        return try await NetworkService.shared.request(url)
    }

    /// 获取示例自选股列表
    static func fetchWatchlist() async throws -> [StockData] {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/watchlist"
        return try await NetworkService.shared.request(url)
    }
}
