import Foundation

/// 市场数据统一请求层
///
/// 处理按交易日查询的接口统一逻辑：
/// 1. 基于 MarketCalendar 获取最近交易日
/// 2. 优先读取缓存
/// 3. 若当天数据不可用（抛错或调用方判定为空），自动回退到前一个交易日
/// 4. 缓存 key 统一包含 tradeDate，方便按日控制
enum MarketDataRequest {
    /// 按最近交易日请求，若结果需要回退则逐日回退到前一个交易日
    ///
    /// - Parameters:
    ///   - keyPrefix: 缓存 key 前缀，建议包含接口标识和参数
    ///   - maxFallbackDays: 最大回退天数（含当天），默认 3
    ///   - policy: 缓存策略
    ///   - ttl: 缓存有效期策略
    ///   - shouldFallback: 判定返回结果是否需要继续回退，默认 false（成功即返回）
    ///   - fetcher: 真正发起请求的闭包，入参为 tradeDate（yyyyMMdd）
    /// - Returns: 实际拉取到的数据和对应的交易日
    static func fetchWithTradeDateFallback<T: Codable>(
        keyPrefix: String,
        maxFallbackDays: Int = 3,
        policy: CachePolicy = .default,
        ttl: CacheTTL = .untilNextTradingDay,
        shouldFallback: @escaping (T) -> Bool = { _ in false },
        fetcher: (_ tradeDate: String) async throws -> T
    ) async throws -> (data: T, tradeDate: String) {
        let candidateDates = tradeDates(count: maxFallbackDays)

        // 优先读缓存：按最近交易日顺序匹配
        if policy != .skipCache {
            for date in candidateDates {
                let key = cacheKey(prefix: keyPrefix, tradeDate: date)
                if let cached: T = APICacheService.shared.cachedResponse(for: key, ttl: ttl) {
                    return (cached, date)
                }
            }
        }

        // 按候选日期顺序请求，遇到可用结果即返回
        var lastError: Error?
        for date in candidateDates {
            do {
                let value = try await fetcher(date)
                if shouldFallback(value) {
                    continue
                }
                let key = cacheKey(prefix: keyPrefix, tradeDate: date)
                APICacheService.shared.save(value, for: key)
                return (value, date)
            } catch {
                lastError = error
                continue
            }
        }

        if let lastError {
            throw lastError
        }
        throw APIError.noData
    }

    private static func cacheKey(prefix: String, tradeDate: String) -> String {
        "\(prefix)_\(tradeDate)"
    }

    /// 生成最近 N 个交易日的日期字符串（yyyyMMdd），从最近交易日开始往前推
    private static func tradeDates(count: Int) -> [String] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = MarketCalendar.timeZone

        var dates: [String] = []
        var current = MarketCalendar.latestTradeDate()
        dates.append(MarketCalendar.formatTradeDate(current))

        for _ in 1..<count {
            var previous = calendar.date(byAdding: .day, value: -1, to: current) ?? current
            while !MarketCalendar.isTradeDay(previous) {
                previous = calendar.date(byAdding: .day, value: -1, to: previous) ?? previous
            }
            dates.append(MarketCalendar.formatTradeDate(previous))
            current = previous
        }

        return dates
    }
}
