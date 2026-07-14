import Foundation

/// K 线本地缓存服务
///
/// 首次请求全量数据并持久化到本地 JSON 文件，后续进入页面时先展示缓存，
/// 再请求最近一段时间的数据进行合并更新，减少网络等待。
enum KLineCacheService {
    private static let fileManager = FileManager.default

    /// 缓存目录：Documents/kline_cache
    private static var cacheDirectory: URL {
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let directory = urls[0].appendingPathComponent("kline_cache", isDirectory: true)

        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory
    }

    /// 缓存文件路径
    private static func cacheFileURL(code: String, period: KlinePeriod) -> URL {
        let key = "\(code)_\(period.rawValue)".uppercased()
        return cacheDirectory.appendingPathComponent("\(key).json")
    }

    /// 读取缓存
    static func load(code: String, period: KlinePeriod) -> [KlineData] {
        let url = cacheFileURL(code: code, period: period)

        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else {
            return []
        }

        do {
            return try JSONDecoder().decode([KlineData].self, from: data)
        } catch {
            print("读取 K 线缓存失败: \(error.localizedDescription)")
            return []
        }
    }

    /// 保存缓存
    static func save(code: String, period: KlinePeriod, data: [KlineData]) {
        let url = cacheFileURL(code: code, period: period)

        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: url)
        } catch {
            print("保存 K 线缓存失败: \(error.localizedDescription)")
        }
    }

    /// 合并本地缓存与新数据。
    /// 策略：保留本地缓存中早于远端最旧日期的部分，再拼接远端数据。
    /// 这样可以正确处理周K/月K的 tradeDate 每天变化（同一周不同日期）的问题。
    static func merge(local: [KlineData], remote: [KlineData]) -> [KlineData] {
        guard !remote.isEmpty else { return local }
        guard !local.isEmpty else { return remote.sorted { $0.tradeDate < $1.tradeDate } }

        let sortedRemote = remote.sorted { $0.tradeDate < $1.tradeDate }
        let earliestRemoteDate = sortedRemote.first!.tradeDate

        // 本地只保留严格早于远端最早日期的数据（避免同周/同月重复）
        let localOlder = local.filter { $0.tradeDate < earliestRemoteDate }
            .sorted { $0.tradeDate < $1.tradeDate }

        // 拼接：旧本地 + 全部远端
        var merged = localOlder + sortedRemote

        // 最终按日期去重（以防万一）
        var seen: Set<String> = []
        merged = merged.filter { item in
            if seen.contains(item.tradeDate) { return false }
            seen.insert(item.tradeDate)
            return true
        }

        return merged
    }

    /// 清理所有缓存
    static func clearAll() {
        try? fileManager.removeItem(at: cacheDirectory)
    }
}
