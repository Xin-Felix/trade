import Foundation

/// 股票行情数据
struct StockData: Identifiable, Decodable, Hashable {
    let id = UUID()
    let code: String
    let name: String
    let price: Double
    let changePercent: Double
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case code
        case name
        case price
        case changePercent = "change_percent"
        case updatedAt = "updated_at"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    static func == (lhs: StockData, rhs: StockData) -> Bool {
        lhs.code == rhs.code
    }
}

/// K 线数据
struct KlineData: Identifiable, Decodable, Hashable {
    let id = UUID()
    let tsCode: String
    let tradeDate: String
    let period: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double?
    let amount: Double?

    enum CodingKeys: String, CodingKey {
        case tsCode = "ts_code"
        case tradeDate = "trade_date"
        case period
        case open
        case high
        case low
        case close
        case volume
        case amount
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(tsCode)
        hasher.combine(tradeDate)
        hasher.combine(period)
    }

    static func == (lhs: KlineData, rhs: KlineData) -> Bool {
        lhs.tsCode == rhs.tsCode && lhs.tradeDate == rhs.tradeDate && lhs.period == rhs.period
    }
}

enum KlinePeriod: String, CaseIterable {
    case day = "D"
    case week = "W"
    case month = "M"
    case year = "Y"

    var title: String {
        switch self {
        case .day: return "日K"
        case .week: return "周K"
        case .month: return "月K"
        case .year: return "年K"
        }
    }
}
