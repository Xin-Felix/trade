import Foundation

enum StockService {
    /// 获取单只股票最新行情
    static func fetchQuote(code: String, policy: CachePolicy = .default) async throws -> StockData {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/quote/\(code)"
        let key = "quote_\(code)"
        // 行情实时性要求高：盘中 60s，盘后长期有效
        return try await APICacheService.shared.fetch(key: key, policy: policy, ttl: .untilNextTradingDay) {
            try await NetworkService.shared.request(url)
        }
    }

    /// 获取 K 线数据
    static func fetchKlines(code: String, period: KlinePeriod = .day, limit: Int = 60) async throws -> [KlineData] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/klines/\(code)")!
        components.queryItems = [
            URLQueryItem(name: "period", value: period.apiPeriod),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        return try await NetworkService.shared.request(url)
    }

    /// 获取全部股票基础信息（用于本地缓存和搜索）
    static func fetchStockBasics() async throws -> [StockBasicInfo] {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/basics"
        return try await NetworkService.shared.request(url)
    }

    /// 获取主要大盘指数最新数据
    static func fetchIndices(policy: CachePolicy = .default) async throws -> [IndexItem] {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/indices"
        let key = "indices_\(MarketCalendar.formatTradeDate(MarketCalendar.latestTradeDate()))"
        return try await APICacheService.shared.fetch(key: key, policy: policy, ttl: .untilNextTradingDay) {
            try await NetworkService.shared.request(url)
        }
    }

    /// 国内主要大盘指数（含后端返回的上证/深证/创业板，及补充的科创/北证/上证50/中证500）
    static func fetchDomesticIndices(policy: CachePolicy = .default) async throws -> [IndexItem] {
        let baseIndices = try await fetchIndices(policy: policy)
        let extras = await fetchExtraDomesticIndices()
        let baseCodes = Set(baseIndices.compactMap(\.tsCode))
        return baseIndices + extras.filter { !baseCodes.contains($0.tsCode ?? "") }
    }

    private static func fetchExtraDomesticIndices() async -> [IndexItem] {
        let extras: [(code: String, name: String)] = [
            ("000688.SH", "科创50"),
            ("000698.SH", "科创100"),
            ("899050.BJ", "北证50"),
            ("000016.SH", "上证50"),
            ("000905.SH", "中证500"),
        ]
        return await withTaskGroup(of: (Int, IndexItem?).self) { group in
            for (index, item) in extras.enumerated() {
                group.addTask {
                    let result = try? await fetchIndexDailyLatest(code: item.code, name: item.name)
                    return (index, result)
                }
            }
            var indexed: [(Int, IndexItem)] = []
            for await (index, item) in group {
                if let item = item {
                    indexed.append((index, item))
                }
            }
            return indexed.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    private static func fetchIndexDailyLatest(code: String, name: String) async throws -> IndexItem {
        let data = try await MarketService.fetchIndexDaily(code: code, limit: 1)
        guard let latest = data.first else {
            throw APIError.noData
        }
        return IndexItem(name: name, value: latest.close, change: latest.pctChg, tsCode: code)
    }

    /// 获取全球主要大盘指数最新数据
    static func fetchGlobalIndices(policy: CachePolicy = .default) async throws -> [IndexItem] {
        let url = APIConfiguration.shared.apiV1URL + "/global-market/indices"
        let key = "global_market_indices_\(MarketCalendar.formatTradeDate(MarketCalendar.latestTradeDate()))"
        let response: GlobalMarketIndicesResponse = try await APICacheService.shared.fetch(key: key, policy: policy, ttl: .untilNextTradingDay) {
            try await NetworkService.shared.request(url)
        }
        return response.data.map(IndexItem.from)
    }

    /// 搜索股票（支持代码、名称、拼音缩写）
    static func searchStocks(query: String, limit: Int = 10) async throws -> [StockSearchResult] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        return try await NetworkService.shared.request(url)
    }

    /// 获取自选股列表（从后端获取，再通过批量行情接口一次拉取所有报价）
    static func fetchWatchlist() async throws -> [StockData] {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/watchlist"
        let response: WatchlistResponse = try await NetworkService.shared.request(url)
        let items = response.items
        // 同步后端数据到本地缓存
        WatchlistService.syncFromBackend(items)
        guard !items.isEmpty else { return [] }
        // 优先使用批量接口（1 个请求），失败则降级为并发逐个拉取
        let codes = items.map(\.code).joined(separator: ",")
        do {
            return try await fetchQuotesBatch(codes: codes)
        } catch {
            // 降级：并发拉取每只股票行情
            return await withTaskGroup(of: (Int, StockData?).self) { group in
                for (index, item) in items.enumerated() {
                    group.addTask {
                        let stock = try? await fetchQuote(code: item.code)
                        return (index, stock)
                    }
                }
                var indexed: [(Int, StockData)] = []
                for await (index, stock) in group {
                    if let stock = stock {
                        indexed.append((index, stock))
                    }
                }
                return indexed.sorted { $0.0 < $1.0 }.map(\.1)
            }
        }
    }

    /// 批量获取多只股票行情（单次请求）
    static func fetchQuotesBatch(codes: String) async throws -> [StockData] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/quotes")!
        components.queryItems = [
            URLQueryItem(name: "codes", value: codes)
        ]
        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }
        return try await NetworkService.shared.request(url)
    }

        /// 聚合详情响应
    struct StockDetailResponse: Codable {
        let quote: StockData
        let dailyBasic: DailyBasicData?
        let concepts: [StockConcept]
        let moneyflow: [MoneyFlowData]

        enum CodingKeys: String, CodingKey {
            case quote
            case dailyBasic = "daily_basic"
            case concepts
            case moneyflow
        }
    }

    /// 获取股票聚合详情（quote + dailyBasic + concepts + moneyflow，1个请求）
    static func fetchStockDetail(code: String, policy: CachePolicy = .default) async throws -> StockDetailResponse {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/detail/\(code)"
        let key = "stock_detail_\(code)_\(MarketCalendar.formatTradeDate(MarketCalendar.latestTradeDate()))"
        return try await APICacheService.shared.fetch(key: key, policy: policy, ttl: .untilNextTradingDay) {
            try await NetworkService.shared.request(url)
        }
    }

    /// 添加自选股（后端）
    static func addToWatchlist(code: String, name: String) async throws {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/watchlist"
        let body = WatchlistAddBody(code: code, name: name)
        let _: WatchlistItemData = try await NetworkService.shared.request(url, method: .post, body: body)
    }

    /// 删除自选股（后端）
    static func removeFromWatchlist(code: String) async throws {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/watchlist/\(code)"
        try await NetworkService.shared.requestVoid(url, method: .delete)
    }

    /// 获取持仓列表
    static func fetchPortfolio() async throws -> [PortfolioItem] {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/portfolio"
        let response: PortfolioResponse = try await NetworkService.shared.request(url)
        return response.items
    }

    /// 添加持仓
    static func addToPortfolio(
        code: String,
        name: String,
        costPrice: Double? = nil,
        quantity: Double? = nil,
        isMargin: Bool? = nil,
        note: String? = nil
    ) async throws -> PortfolioItem {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/portfolio"
        let body = PortfolioAddBody(
            code: code,
            name: name,
            costPrice: costPrice,
            quantity: quantity,
            isMargin: isMargin,
            note: note
        )
        return try await NetworkService.shared.request(url, method: .post, body: body)
    }

    /// 更新持仓
    static func updatePortfolio(
        code: String,
        costPrice: Double? = nil,
        quantity: Double? = nil,
        isMargin: Bool? = nil,
        note: String? = nil
    ) async throws -> PortfolioItem {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/portfolio/\(code)"
        let body = PortfolioUpdateBody(
            costPrice: costPrice,
            quantity: quantity,
            isMargin: isMargin,
            note: note
        )
        return try await NetworkService.shared.request(url, method: .patch, body: body)
    }

    /// 删除持仓
    static func removeFromPortfolio(code: String) async throws {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/portfolio/\(code)"
        try await NetworkService.shared.requestVoid(url, method: .delete)
    }

    /// 通过 OCR 文本导入持仓（替换现有持仓）
    static func importPortfolioFromText(_ text: String) async throws -> PortfolioImportResponse {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/portfolio/import-text"
        let body = PortfolioImportBody(text: text)
        return try await NetworkService.shared.request(url, method: .post, body: body)
    }

    /// 获取分时 K 线数据（1/5/15/30/60 分钟）
    /// - tradeDate 为 nil 时请求最新实时数据（盘中走 akshare），不跨交易日缓存
    static func fetchIntradayKlines(code: String, period: String = "1", limit: Int = 241, tradeDate: String? = nil, policy: CachePolicy = .default) async throws -> [IntradayKlineData] {
        if let tradeDate = tradeDate {
            // 查看指定历史交易日：走按交易日回退缓存
            let (items, _) = try await MarketDataRequest.fetchWithTradeDateFallback(
                keyPrefix: "intraday_\(code)_\(period)_\(limit)",
                policy: policy,
                ttl: .untilNextTradingDay,
                shouldFallback: { $0.isEmpty }
            ) { date in
                try await fetchIntradayKlinesRaw(code: code, period: period, limit: limit, tradeDate: date)
            }
            return items
        }

        // 请求最新实时数据：短缓存 30s，避免盘中显示旧数据
        let key = "intraday_live_\(code)_\(period)_\(limit)"
        return try await APICacheService.shared.fetch(key: key, policy: policy, ttl: .seconds(30)) {
            try await fetchIntradayKlinesLive(code: code, period: period, limit: limit)
        }
    }

    private static func fetchIntradayKlinesRaw(code: String, period: String, limit: Int, tradeDate: String) async throws -> [IntradayKlineData] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/intraday/\(code)")!
        components.queryItems = [
            URLQueryItem(name: "period", value: period),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "trade_date", value: tradeDate)
        ]
        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }
        return try await NetworkService.shared.request(url)
    }

    private static func fetchIntradayKlinesLive(code: String, period: String, limit: Int) async throws -> [IntradayKlineData] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/intraday/\(code)")!
        components.queryItems = [
            URLQueryItem(name: "period", value: period),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }
        return try await NetworkService.shared.request(url)
    }

    /// 获取股票日线因子数据（PE/PB/换手率等）
    static func fetchDailyBasic(code: String, limit: Int = 1, policy: CachePolicy = .default) async throws -> [DailyBasicData] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/daily-basic/\(code)")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        let key = "daily_basic_\(code)_\(limit)_\(MarketCalendar.formatTradeDate(MarketCalendar.latestTradeDate()))"
        return try await APICacheService.shared.fetch(key: key, policy: policy, ttl: .untilNextTradingDay) {
            try await NetworkService.shared.request(url)
        }
    }

    /// 获取某只股票所属的全部概念/题材板块
    static func fetchConcepts(code: String, policy: CachePolicy = .default) async throws -> [StockConcept] {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/concepts/\(code)"
        let key = "concepts_\(code)_\(MarketCalendar.formatTradeDate(MarketCalendar.latestTradeDate()))"
        return try await APICacheService.shared.fetch(key: key, policy: policy, ttl: .untilNextTradingDay) {
            try await NetworkService.shared.request(url)
        }
    }

    /// 获取上市公司基本信息（公司简介、主营业务等）
    static func fetchStockCompany(code: String) async throws -> StockCompanyInfo? {
        let url = APIConfiguration.shared.apiV1URL + "/ts/stock-company/\(code)"
        let list: [StockCompanyInfo] = try await NetworkService.shared.request(url)
        return list.first
    }

    /// 获取上市公司财务指标数据（ROE/EPS/毛利率等）
    static func fetchFinaIndicator(code: String, limit: Int = 1) async throws -> FinaIndicator? {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/ts/fina-indicator/\(code)")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]
        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }
        let list: [FinaIndicator] = try await NetworkService.shared.request(url)
        return list.first
    }

    /// 获取板块资金流排行（行业/概念）
    static func fetchSectorMoneyflow(
        sectorType: SectorMoneyflowType = .industry,
        tradeDate: String? = nil,
        sortBy: String = "net_amount",
        limit: Int = 20,
        policy: CachePolicy = .default
    ) async throws -> SectorMoneyflowRankResponse {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/sector-moneyflow")!
        var queryItems = [
            URLQueryItem(name: "sector_type", value: sectorType.rawValue),
            URLQueryItem(name: "sort_by", value: sortBy),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        let date = tradeDate ?? MarketCalendar.formatTradeDate(MarketCalendar.latestTradeDate())
        queryItems.append(URLQueryItem(name: "trade_date", value: date))
        components.queryItems = queryItems

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        let key = "sector_moneyflow_\(sectorType.rawValue)_\(sortBy)_\(limit)_\(date)"
        return try await APICacheService.shared.fetch(key: key, policy: policy, ttl: .untilNextTradingDay) {
            try await NetworkService.shared.request(url)
        }
    }

    /// 获取板块资金流动态趋势（时间段）
    static func fetchSectorMoneyflowTrend(
        sectorType: SectorMoneyflowType = .industry,
        startDate: String,
        endDate: String,
        topN: Int = 30,
        tsCodes: [String]? = nil,
        policy: CachePolicy = .default
    ) async throws -> SectorMoneyflowTrendResponse {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/sector-moneyflow/trend")!
        components.queryItems = [
            URLQueryItem(name: "sector_type", value: sectorType.rawValue),
            URLQueryItem(name: "start_date", value: startDate),
            URLQueryItem(name: "end_date", value: endDate),
            URLQueryItem(name: "top_n", value: String(topN))
        ]
        if let tsCodes, !tsCodes.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "ts_codes", value: tsCodes.joined(separator: ",")))
        }

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        let codesKey = tsCodes?.joined(separator: "_") ?? ""
        let key = "sector_moneyflow_trend_\(sectorType.rawValue)_\(startDate)_\(endDate)_\(topN)_\(codesKey)"
        return try await APICacheService.shared.fetch(key: key, policy: policy, ttl: .untilNextTradingDay) {
            try await NetworkService.shared.request(url)
        }
    }
}


// MARK: - 自选股服务（后端同步 + 本地缓存镜像）

/// 添加自选股请求体
private struct WatchlistAddBody: Encodable {
    let code: String
    let name: String
}

/// 自选股服务，数据以后端为准，本地缓存用于快速 UI 判断（如星标图标）。
enum WatchlistService {
    private static let key = "yingplus_watchlist"

    struct WatchlistItem: Codable {
        let code: String
        let name: String
    }

    /// 从本地缓存读取（用于快速 UI 判断）
    static func load() -> [WatchlistItem] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([WatchlistItem].self, from: data) else {
            return []
        }
        return items
    }

    /// 保存到本地缓存
    static func save(_ items: [WatchlistItem]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// 从后端响应同步到本地缓存
    static func syncFromBackend(_ backendItems: [WatchlistItemData]) {
        let items = backendItems.map { WatchlistItem(code: $0.code, name: $0.name) }
        save(items)
    }

    /// 添加自选股（先更新本地缓存，再异步同步后端）
    static func add(code: String, name: String) -> Bool {
        let limit = 20
        var items = load()
        guard !items.contains(where: { $0.code == code }) else { return true }
        guard items.count < limit else {
            print("[WatchlistService] 自选股数量已达上限 \(limit) 只，建议精简票池后再添加")
            return false
        }
        items.append(WatchlistItem(code: code, name: name))
        save(items)

        // 异步同步到后端
        Task {
            do {
                try await StockService.addToWatchlist(code: code, name: name)
            } catch {
                print("[WatchlistService] 添加自选股到后端失败: \(error.localizedDescription)")
            }
        }
        return true
    }

    /// 删除自选股（先更新本地缓存，再异步同步后端）
    static func remove(code: String) {
        var items = load()
        items.removeAll { $0.code == code }
        save(items)

        // 异步同步到后端
        Task {
            do {
                try await StockService.removeFromWatchlist(code: code)
            } catch {
                print("[WatchlistService] 从后端删除自选股失败: \(error.localizedDescription)")
            }
        }
    }

    /// 判断是否已添加
    static func contains(code: String) -> Bool {
        load().contains { $0.code == code }
    }
}


// MARK: - 股票列表本地缓存

/// 全部股票基础信息本地缓存，每天从后台刷新一次，搜索时直接读本地。
enum StockListCacheService {
    private static let fileManager = FileManager.default
    private static let cacheFileName = "stock_basics.json"
    private static let lastFetchKey = "stock_basics_last_fetch_date"

    private static var cacheFileURL: URL {
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent(cacheFileName)
    }

    static func load() -> [StockBasicInfo] {
        guard fileManager.fileExists(atPath: cacheFileURL.path),
              let data = try? Data(contentsOf: cacheFileURL) else {
            return []
        }

        do {
            return try JSONDecoder().decode([StockBasicInfo].self, from: data)
        } catch {
            print("读取股票列表缓存失败: \(error.localizedDescription)")
            return []
        }
    }

    static func save(_ stocks: [StockBasicInfo]) {
        do {
            let data = try JSONEncoder().encode(stocks)
            try data.write(to: cacheFileURL)
            updateLastFetchDate()
        } catch {
            print("保存股票列表缓存失败: \(error.localizedDescription)")
        }
    }

    static func shouldRefresh() -> Bool {
        guard !load().isEmpty else { return true }

        let lastFetch = UserDefaults.standard.object(forKey: lastFetchKey) as? Date
        guard let lastFetch else { return true }

        let oneDay: TimeInterval = 24 * 60 * 60
        return Date().timeIntervalSince(lastFetch) > oneDay
    }

    static func updateLastFetchDate() {
        UserDefaults.standard.set(Date(), forKey: lastFetchKey)
    }

    static func clear() {
        try? fileManager.removeItem(at: cacheFileURL)
        UserDefaults.standard.removeObject(forKey: lastFetchKey)
    }
}
