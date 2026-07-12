import Foundation

/// 市场数据服务 — 大盘指数、北向资金、龙虎榜等市场级数据
enum MarketService {

    // MARK: - 北向资金

    /// 获取北向资金（沪深港通）近期数据
    static func fetchHsgtFlow(limit: Int = 10, policy: CachePolicy = .default) async throws -> [HsgtFlowData] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/moneyflow-hsgt")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        let key = "hsgt_\(limit)_\(MarketCalendar.formatTradeDate(MarketCalendar.latestTradeDate()))"
        return try await APICacheService.shared.fetch(key: key, policy: policy, ttl: .untilNextTradingDay) {
            try await NetworkService.shared.request(url)
        }
    }

    // MARK: - 龙虎榜

    /// 获取龙虎榜每日明细
    static func fetchTopList(tradeDate: String? = nil, limit: Int = 20, policy: CachePolicy = .default) async throws -> [TopListItem] {
        if let tradeDate = tradeDate {
            let response = try await fetchTopListRaw(tradeDate: tradeDate, limit: limit)
            return response.items
        }

        let (response, _) = try await MarketDataRequest.fetchWithTradeDateFallback(
            keyPrefix: "toplist_\(limit)",
            policy: policy,
            ttl: .untilNextTradingDay,
            shouldFallback: { $0.items.isEmpty }
        ) { date in
            try await fetchTopListRaw(tradeDate: date, limit: limit)
        }
        return response.items
    }

    private static func fetchTopListRaw(tradeDate: String, limit: Int) async throws -> TopListResponse {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/top-list")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "trade_date", value: tradeDate)
        ]
        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }
        let response: TopListResponse = try await NetworkService.shared.request(url)
        return response
    }

    /// 获取龙虎榜机构明细
    static func fetchTopInst(tradeDate: String? = nil, code: String? = nil, limit: Int = 20, policy: CachePolicy = .default) async throws -> [TopInstItem] {
        if let tradeDate = tradeDate {
            return try await fetchTopInstRaw(tradeDate: tradeDate, code: code, limit: limit)
        }

        let (items, _) = try await MarketDataRequest.fetchWithTradeDateFallback(
            keyPrefix: "topinst_\(code ?? "all")_\(limit)",
            policy: policy,
            ttl: .untilNextTradingDay,
            shouldFallback: { $0.isEmpty }
        ) { date in
            try await fetchTopInstRaw(tradeDate: date, code: code, limit: limit)
        }
        return items
    }

    private static func fetchTopInstRaw(tradeDate: String, code: String?, limit: Int) async throws -> [TopInstItem] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/top-inst")!
        var queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        queryItems.append(URLQueryItem(name: "trade_date", value: tradeDate))
        if let code = code {
            queryItems.append(URLQueryItem(name: "code", value: code))
        }
        components.queryItems = queryItems
        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }
        return try await NetworkService.shared.request(url)
    }

    // MARK: - 指数日线

    /// 获取指数日线数据
    static func fetchIndexDaily(code: String, limit: Int = 30, policy: CachePolicy = .default) async throws -> [IndexDailyData] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/index-daily/\(code)")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        let key = "index_daily_\(code)_\(limit)"
        return try await APICacheService.shared.fetch(key: key, policy: policy, ttl: .untilNextTradingDay) {
            try await NetworkService.shared.request(url)
        }
    }

    // MARK: - 个股资金流

    /// 获取个股资金流向
    static func fetchMoneyFlow(code: String, limit: Int = 10, policy: CachePolicy = .default) async throws -> [MoneyFlowData] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/moneyflow/\(code)")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        let key = "moneyflow_\(code)_\(limit)_\(MarketCalendar.formatTradeDate(MarketCalendar.latestTradeDate()))"
        return try await APICacheService.shared.fetch(key: key, policy: policy, ttl: .untilNextTradingDay) {
            try await NetworkService.shared.request(url)
        }
    }

    // MARK: - 板块成分股

    /// 获取板块成分股列表
    static func fetchSectorMembers(
        code: String,
        page: Int = 1,
        pageSize: Int = 20,
        sortBy: String? = nil,
        sortOrder: String? = nil,
        board: String? = nil,
        policy: CachePolicy = .default
    ) async throws -> [SectorMemberItem] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/ths-member/\(code)")!
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: String(pageSize))
        ]
        if let sortBy = sortBy {
            queryItems.append(URLQueryItem(name: "sort_by", value: sortBy))
        }
        if let sortOrder = sortOrder {
            queryItems.append(URLQueryItem(name: "sort_order", value: sortOrder))
        }
        if let board = board, board != "all" {
            queryItems.append(URLQueryItem(name: "board", value: board))
        }
        components.queryItems = queryItems

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        let key = "sector_members_\(code)_\(page)_\(pageSize)_\(sortBy ?? "")_\(sortOrder ?? "")_\(board ?? "all")_\(MarketCalendar.formatTradeDate(MarketCalendar.latestTradeDate()))"
        return try await APICacheService.shared.fetch(key: key, policy: policy, ttl: .untilNextTradingDay) {
            try await NetworkService.shared.request(url)
        }
    }

    // MARK: - 概念成分股

    /// 获取概念成分股列表（Tushare 概念）
    static func fetchConceptMembers(
        conceptId: String,
        page: Int = 1,
        pageSize: Int = 200,
        policy: CachePolicy = .default
    ) async throws -> [SectorMemberItem] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/ts/concept-detail/\(conceptId)")!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: String(pageSize))
        ]

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        let key = "concept_members_\(conceptId)_\(page)_\(pageSize)_\(MarketCalendar.formatTradeDate(MarketCalendar.latestTradeDate()))"
        let response: ConceptDetailResponse = try await APICacheService.shared.fetch(key: key, policy: policy, ttl: .untilNextTradingDay) {
            try await NetworkService.shared.request(url)
        }

        return response.data.items.map {
            SectorMemberItem(
                tsCode: $0.tsCode,
                conCode: $0.tsCode,
                conName: $0.name,
                pctChange: nil,
                board: nil
            )
        }
    }

    // MARK: - 涨停梯队

    /// 获取涨停梯队数据
    static func fetchLimitUpLadder(tradeDate: String? = nil, policy: CachePolicy = .default) async throws -> LimitUpLadderResponse {
        if let tradeDate = tradeDate {
            return try await fetchLimitUpLadderRaw(tradeDate: tradeDate)
        }

        let (response, _) = try await MarketDataRequest.fetchWithTradeDateFallback(
            keyPrefix: "limitup",
            policy: policy,
            ttl: .untilNextTradingDay,
            shouldFallback: { $0.ladder.isEmpty }
        ) { date in
            try await fetchLimitUpLadderRaw(tradeDate: date)
        }
        return response
    }

    private static func fetchLimitUpLadderRaw(tradeDate: String) async throws -> LimitUpLadderResponse {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/limit-up-ladder")!
        components.queryItems = [URLQueryItem(name: "trade_date", value: tradeDate)]
        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }
        return try await NetworkService.shared.request(url)
    }
}
