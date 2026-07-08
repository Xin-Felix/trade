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

    /// 获取全部股票基础信息（用于本地缓存和搜索）
    static func fetchStockBasics() async throws -> [StockBasicInfo] {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/basics"
        return try await NetworkService.shared.request(url)
    }

    /// 获取主要大盘指数最新数据
    static func fetchIndices() async throws -> [IndexItem] {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/indices"
        return try await NetworkService.shared.request(url)
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

    /// 获取自选股列表（从本地缓存读取并刷新行情）
    static func fetchWatchlist() async throws -> [StockData] {
        let codes = WatchlistService.load()
        guard !codes.isEmpty else { return [] }

        return await withTaskGroup(of: StockData?.self) { group in
            for item in codes {
                group.addTask {
                    try? await fetchQuote(code: item.code)
                }
            }

            var result: [StockData] = []
            for await stock in group {
                if let stock = stock {
                    result.append(stock)
                }
            }
            return result
        }
    }

    /// 获取股票日线因子数据（PE/PB/换手率等）
    static func fetchDailyBasic(code: String, limit: Int = 1) async throws -> [DailyBasicData] {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/daily-basic/\(code)")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        return try await NetworkService.shared.request(url)
    }

    /// 获取板块资金流排行（行业/概念）
    static func fetchSectorMoneyflow(
        sectorType: SectorMoneyflowType = .industry,
        tradeDate: String? = nil,
        sortBy: String = "net_amount",
        limit: Int = 20
    ) async throws -> SectorMoneyflowRankResponse {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/sector-moneyflow")!
        var queryItems = [
            URLQueryItem(name: "sector_type", value: sectorType.rawValue),
            URLQueryItem(name: "sort_by", value: sortBy),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let tradeDate = tradeDate {
            queryItems.append(URLQueryItem(name: "trade_date", value: tradeDate))
        }
        components.queryItems = queryItems

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        return try await NetworkService.shared.request(url)
    }

    /// 获取板块资金流动态趋势（时间段）
    static func fetchSectorMoneyflowTrend(
        sectorType: SectorMoneyflowType = .industry,
        startDate: String,
        endDate: String,
        topN: Int = 30
    ) async throws -> SectorMoneyflowTrendResponse {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/stocks/sector-moneyflow/trend")!
        components.queryItems = [
            URLQueryItem(name: "sector_type", value: sectorType.rawValue),
            URLQueryItem(name: "start_date", value: startDate),
            URLQueryItem(name: "end_date", value: endDate),
            URLQueryItem(name: "top_n", value: String(topN))
        ]

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        return try await NetworkService.shared.request(url)
    }
}


// MARK: - 自选股本地缓存

/// 自选股本地缓存服务，使用 UserDefaults 存储用户手动添加的股票代码。
enum WatchlistService {
    private static let key = "yingplus_watchlist"

    struct WatchlistItem: Codable {
        let code: String
        let name: String
    }

    static func load() -> [WatchlistItem] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([WatchlistItem].self, from: data) else {
            return []
        }
        return items
    }

    static func save(_ items: [WatchlistItem]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func add(code: String, name: String) {
        var items = load()
        guard !items.contains(where: { $0.code == code }) else { return }
        items.append(WatchlistItem(code: code, name: name))
        save(items)
    }

    static func remove(code: String) {
        var items = load()
        items.removeAll { $0.code == code }
        save(items)
    }

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
