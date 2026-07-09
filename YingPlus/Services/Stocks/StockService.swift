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

    /// 获取自选股列表（从后端获取，按加入时间排序，然后并发拉取行情）
    static func fetchWatchlist() async throws -> [StockData] {
        let url = APIConfiguration.shared.apiV1URL + "/stocks/watchlist"
        let response: WatchlistResponse = try await NetworkService.shared.request(url)
        let items = response.items
        guard !items.isEmpty else { return [] }

        // 并发拉取行情，保持后端返回的顺序
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

    /// 获取分时 K 线数据（1/5/15/30/60 分钟）
    static func fetchIntradayKlines(code: String, period: String = "1", limit: Int = 240) async throws -> [IntradayKlineData] {
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
    static func add(code: String, name: String) {
        var items = load()
        guard !items.contains(where: { $0.code == code }) else { return }
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
