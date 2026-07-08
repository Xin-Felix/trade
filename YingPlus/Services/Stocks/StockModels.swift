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

/// 股票基础信息（用于本地缓存和搜索）
struct StockBasicInfo: Identifiable, Codable, Hashable {
    let id = UUID()
    let code: String
    let name: String
    let cnspell: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    static func == (lhs: StockBasicInfo, rhs: StockBasicInfo) -> Bool {
        lhs.code == rhs.code
    }
}

/// 股票搜索结果
struct StockSearchResult: Identifiable, Decodable, Hashable {
    let id = UUID()
    let code: String
    let name: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    static func == (lhs: StockSearchResult, rhs: StockSearchResult) -> Bool {
        lhs.code == rhs.code
    }
}

/// K 线数据
struct KlineData: Identifiable, Codable, Hashable {
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

/// 股票日线因子数据
struct DailyBasicData: Identifiable, Decodable, Hashable {
    let id = UUID()
    let tsCode: String
    let tradeDate: String
    let close: Double?
    let turnoverRate: Double?
    let turnoverRateF: Double?
    let volumeRatio: Double?
    let pe: Double?
    let peTtm: Double?
    let pb: Double?
    let ps: Double?
    let psTtm: Double?
    let dvRatio: Double?
    let dvTtm: Double?
    let totalShare: Double?
    let floatShare: Double?
    let freeShare: Double?
    let totalMv: Double?
    let circMv: Double?

    enum CodingKeys: String, CodingKey {
        case tsCode = "ts_code"
        case tradeDate = "trade_date"
        case close
        case turnoverRate = "turnover_rate"
        case turnoverRateF = "turnover_rate_f"
        case volumeRatio = "volume_ratio"
        case pe
        case peTtm = "pe_ttm"
        case pb
        case ps
        case psTtm = "ps_ttm"
        case dvRatio = "dv_ratio"
        case dvTtm = "dv_ttm"
        case totalShare = "total_share"
        case floatShare = "float_share"
        case freeShare = "free_share"
        case totalMv = "total_mv"
        case circMv = "circ_mv"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(tsCode)
        hasher.combine(tradeDate)
    }

    static func == (lhs: DailyBasicData, rhs: DailyBasicData) -> Bool {
        lhs.tsCode == rhs.tsCode && lhs.tradeDate == rhs.tradeDate
    }
}

/// 板块类型
enum SectorMoneyflowType: String {
    case industry
    case concept
}

/// 板块资金流数据
struct SectorMoneyflowData: Identifiable, Decodable, Hashable {
    let id = UUID()
    let tsCode: String
    let tradeDate: String
    let name: String?
    let leadStock: String?
    let closePrice: Double?
    let pctChange: Double?
    let companyNum: Int?
    let pctChangeStock: Double?
    let netBuyAmount: Double?
    let netSellAmount: Double?
    let netAmount: Double?

    enum CodingKeys: String, CodingKey {
        case tsCode = "ts_code"
        case tradeDate = "trade_date"
        case name
        case leadStock = "lead_stock"
        case closePrice = "close_price"
        case pctChange = "pct_change"
        case companyNum = "company_num"
        case pctChangeStock = "pct_change_stock"
        case netBuyAmount = "net_buy_amount"
        case netSellAmount = "net_sell_amount"
        case netAmount = "net_amount"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(tsCode)
        hasher.combine(tradeDate)
    }

    static func == (lhs: SectorMoneyflowData, rhs: SectorMoneyflowData) -> Bool {
        lhs.tsCode == rhs.tsCode && lhs.tradeDate == rhs.tradeDate
    }
}

/// 板块资金流排行响应
struct SectorMoneyflowRankResponse: Decodable {
    let sectors: [SectorMoneyflowData]
    let tradeDate: String
    let sectorType: String

    enum CodingKeys: String, CodingKey {
        case sectors
        case tradeDate = "trade_date"
        case sectorType = "sector_type"
    }
}

/// 板块资金流动态趋势响应
struct SectorMoneyflowTrendResponse: Decodable {
    let sectorType: String
    let startDate: String
    let endDate: String
    let dates: [String]
    let series: [SectorMoneyflowSeries]

    enum CodingKeys: String, CodingKey {
        case sectorType = "sector_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case dates
        case series
    }
}

/// 板块资金流趋势单条序列
struct SectorMoneyflowSeries: Identifiable, Decodable {
    let id = UUID()
    let tsCode: String
    let name: String
    let values: [SectorMoneyflowTrendPoint]

    enum CodingKeys: String, CodingKey {
        case tsCode = "ts_code"
        case name
        case values
    }
}

/// 板块资金流趋势单天数据点
struct SectorMoneyflowTrendPoint: Decodable {
    let tradeDate: String
    let netAmount: Double
    let pctChange: Double?

    enum CodingKeys: String, CodingKey {
        case tradeDate = "trade_date"
        case netAmount = "net_amount"
        case pctChange = "pct_change"
    }
}
