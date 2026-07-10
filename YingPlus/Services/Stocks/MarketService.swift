import Foundation

/// 市场数据服务 — 大盘指数、北向资金、龙虎榜等市场级数据
enum MarketService {

    // MARK: - 北向资金

    /// 获取北向资金（沪深港通）近期数据
    static func fetchHsgtFlow(limit: Int = 10) async throws -> [HsgtFlowData] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/moneyflow-hsgt")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        return try await NetworkService.shared.request(url)
    }

    // MARK: - 龙虎榜

    /// 获取龙虎榜每日明细
    static func fetchTopList(tradeDate: String? = nil, limit: Int = 20) async throws -> [TopListItem] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/top-list")!
        var queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        if let date = tradeDate {
            queryItems.append(URLQueryItem(name: "trade_date", value: date))
        }
        components.queryItems = queryItems

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        return try await NetworkService.shared.request(url)
    }

    /// 获取龙虎榜机构明细
    static func fetchTopInst(tradeDate: String? = nil, limit: Int = 20) async throws -> [TopInstItem] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/top-inst")!
        var queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        if let date = tradeDate {
            queryItems.append(URLQueryItem(name: "trade_date", value: date))
        }
        components.queryItems = queryItems

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        return try await NetworkService.shared.request(url)
    }

    // MARK: - 指数日线

    /// 获取指数日线数据
    static func fetchIndexDaily(code: String, limit: Int = 30) async throws -> [IndexDailyData] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/index-daily/\(code)")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        return try await NetworkService.shared.request(url)
    }

    // MARK: - 个股资金流

    /// 获取个股资金流向
    static func fetchMoneyFlow(code: String, limit: Int = 10) async throws -> [MoneyFlowData] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/moneyflow/\(code)")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        return try await NetworkService.shared.request(url)
    }

    // MARK: - 板块成分股

    /// 获取板块成分股列表
    static func fetchSectorMembers(code: String) async throws -> [SectorMemberItem] {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/ths-member/\(code)"
        return try await NetworkService.shared.request(url)
    }
}
