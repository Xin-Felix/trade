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

    /// 合并本地缓存与新数据，按 tradeDate 去重，保留新数据
    static func merge(local: [KlineData], remote: [KlineData]) -> [KlineData] {
        var mergedByDate: [String: KlineData] = [:]

        for item in local {
            mergedByDate[item.tradeDate] = item
        }

        for item in remote {
            mergedByDate[item.tradeDate] = item
        }

        return mergedByDate.values.sorted { $0.tradeDate < $1.tradeDate }
    }

    /// 清理所有缓存
    static func clearAll() {
        try? fileManager.removeItem(at: cacheDirectory)
    }
}
