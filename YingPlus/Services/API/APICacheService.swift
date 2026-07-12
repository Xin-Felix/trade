import Foundation

/// 缓存策略
enum CachePolicy {
    /// 默认：缓存有效则直接返回，否则请求网络并写缓存
    case `default`
    /// 强制跳过缓存，直接请求网络
    case skipCache
}

extension CachePolicy: Equatable, Sendable {}

/// 缓存有效期策略
enum CacheTTL {
    /// 固定秒数
    case seconds(TimeInterval)
    /// 直到下一交易日开盘（适用于收盘后不变的数据）
    case untilNextTradingDay
}

extension CacheTTL: Equatable, Sendable {}

/// 通用 API 缓存服务：内存 + 磁盘两级缓存
final class APICacheService {
    static let shared = APICacheService()

    private let fileManager = FileManager.default
    private let memoryCache = NSCache<NSString, CacheEntry>()
    private let lock = NSLock()

    private final class CacheEntry: Codable {
        let data: Data
        let timestamp: Date

        init(data: Data, timestamp: Date) {
            self.data = data
            self.timestamp = timestamp
        }
    }

    private var cacheDirectory: URL {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let directory = urls[0].appendingPathComponent("api_cache", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    private func cacheFileURL(for key: String) -> URL {
        let safeKey = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return cacheDirectory.appendingPathComponent("\(safeKey).json")
    }

    // MARK: - 缓存有效期判断

    private func isValid(entry: CacheEntry, ttl: CacheTTL, now: Date) -> Bool {
        switch ttl {
        case .seconds(let interval):
            return now.timeIntervalSince(entry.timestamp) < interval
        case .untilNextTradingDay:
            // 如果在交易时段内，当作 60s 过期；否则缓存在下一交易日 09:30 前有效
            if MarketCalendar.isTradingTime(now) {
                return now.timeIntervalSince(entry.timestamp) < 60
            }
            let nextOpen = MarketCalendar.nextTradingDayOpenTime(now)
            return entry.timestamp < nextOpen && now < nextOpen
        }
    }

    // MARK: - 读取

    func cachedResponse<T: Codable>(for key: String, ttl: CacheTTL) -> T? {
        let now = Date()

        lock.lock()
        let memoryEntry = memoryCache.object(forKey: key as NSString)
        lock.unlock()

        if let entry = memoryEntry, isValid(entry: entry, ttl: ttl, now: now) {
            return try? JSONDecoder().decode(T.self, from: entry.data)
        }

        let url = cacheFileURL(for: key)
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let entry = try? JSONDecoder().decode(CacheEntry.self, from: data),
              isValid(entry: entry, ttl: ttl, now: now) else {
            return nil
        }

        // 回写内存
        lock.lock()
        memoryCache.setObject(entry, forKey: key as NSString)
        lock.unlock()

        return try? JSONDecoder().decode(T.self, from: entry.data)
    }

    // MARK: - 写入

    func save<T: Codable>(_ value: T, for key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        let entry = CacheEntry(data: data, timestamp: Date())

        // 内存
        lock.lock()
        memoryCache.setObject(entry, forKey: key as NSString)
        lock.unlock()

        // 磁盘（不抛异常到业务层）
        let url = cacheFileURL(for: key)
        DispatchQueue.global(qos: .utility).async {
            try? data.write(to: url)
        }
    }

    // MARK: - 通用包装

    /// 带缓存的通用请求方法
    /// - Parameters:
    ///   - key: 缓存 key，建议包含参数和 tradeDate
    ///   - policy: 缓存策略
    ///   - ttl: 有效期策略
    ///   - fetcher: 真正发起网络请求的方法
    /// - Returns: 解码后的数据
    func fetch<T: Codable>(
        key: String,
        policy: CachePolicy = .default,
        ttl: CacheTTL,
        fetcher: () async throws -> T
    ) async rethrows -> T {
        if policy != .skipCache, let cached: T = cachedResponse(for: key, ttl: ttl) {
            return cached
        }

        let value = try await fetcher()
        save(value, for: key)
        return value
    }

    // MARK: - 清理

    func clearAll() {
        lock.lock()
        memoryCache.removeAllObjects()
        lock.unlock()
        try? fileManager.removeItem(at: cacheDirectory)
    }

    func remove(for key: String) {
        lock.lock()
        memoryCache.removeObject(forKey: key as NSString)
        lock.unlock()
        try? fileManager.removeItem(at: cacheFileURL(for: key))
    }
}
