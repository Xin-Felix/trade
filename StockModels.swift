import Foundation

// A股基础模型（后续可对接 TuShare 字段做中间转换）

struct StockSymbol: Hashable, Codable, Identifiable {
    var id: String { ticker }
    let ticker: String          // 例如 600519、000001 等
    let name: String?           // 中文名，如 “贵州茅台”
    let exchange: String?       // 可选，如 "SH"/"SZ"
}

struct Quote: Codable, Identifiable, Hashable {
    var id: String { symbol.ticker }
    let symbol: StockSymbol
    let price: Double
    let change: Double          // 相对昨收变化值
    let changePercent: Double   // 变化百分比（0.0123 = 1.23%）
    let time: Date
}

struct Candle: Codable, Identifiable {
    var id: String { "\(symbol.ticker)-\(Int(time.timeIntervalSince1970))" }
    let symbol: StockSymbol
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    let time: Date
}

