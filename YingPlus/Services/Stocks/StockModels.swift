import Foundation

/// 股票行情数据
struct StockData: Identifiable, Codable, Hashable, Sendable {
    let id = UUID()
    let code: String
    let name: String
    let price: Double
    let changePercent: Double
    let preClose: Double?
    let updatedAt: String

    init(code: String, name: String, price: Double, changePercent: Double, preClose: Double? = nil, updatedAt: String) {
        self.code = code
        self.name = name
        self.price = price
        self.changePercent = changePercent
        self.preClose = preClose
        self.updatedAt = updatedAt
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)
        self.name = try container.decode(String.self, forKey: .name)
        self.price = try container.decode(Double.self, forKey: .price)
        self.changePercent = try container.decode(Double.self, forKey: .changePercent)
        self.preClose = try container.decodeIfPresent(Double.self, forKey: .preClose)
        self.updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)
        try container.encode(changePercent, forKey: .changePercent)
        try container.encode(preClose, forKey: .preClose)
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    enum CodingKeys: String, CodingKey {
        case code
        case name
        case price
        case changePercent = "change_percent"
        case preClose = "pre_close"
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
struct StockBasicInfo: Identifiable, Codable, Hashable, Sendable {
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
struct StockSearchResult: Identifiable, Codable, Hashable, Sendable {
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
struct KlineData: Identifiable, Codable, Hashable, Sendable {
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
    case trend = "T"      // 分时走势折线图（UI 专用）
    case intraday = "1"   // 分时 K 线（分钟蜡烛图）
    case day = "D"
    case week = "W"
    case month = "M"
    case year = "Y"

    var title: String {
        switch self {
        case .trend: return "走势"
        case .intraday: return "分时"
        case .day: return "日K"
        case .week: return "周K"
        case .month: return "月K"
        case .year: return "年K"
        }
    }

    var isIntraday: Bool {
        self == .intraday
    }

    var usesIntradayData: Bool {
        self == .trend || self == .intraday
    }

    var apiPeriod: String {
        switch self {
        case .trend, .intraday: return "1"
        case .day, .week, .month, .year: return rawValue
        }
    }
}

/// 分时 K 线数据（分钟级）
struct IntradayKlineData: Identifiable, Codable, Hashable, Sendable {
    let id = UUID()
    let tsCode: String
    let datetime: String
    let period: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double?
    let amount: Double?

    enum CodingKeys: String, CodingKey {
        case tsCode = "ts_code"
        case datetime
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
        hasher.combine(datetime)
        hasher.combine(period)
    }

    static func == (lhs: IntradayKlineData, rhs: IntradayKlineData) -> Bool {
        lhs.tsCode == rhs.tsCode && lhs.datetime == rhs.datetime && lhs.period == rhs.period
    }

    /// 转为 KlineData 格式，方便复用 KLineChartView
    func toKlineData() -> KlineData {
        KlineData(
            tsCode: tsCode,
            tradeDate: datetime,
            period: period,
            open: open,
            high: high,
            low: low,
            close: close,
            volume: volume,
            amount: amount
        )
    }
}

/// 股票日线因子数据
struct DailyBasicData: Identifiable, Codable, Hashable, Sendable {
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

// MARK: - 自选股后端响应

/// 后端自选股列表项
struct WatchlistItemData: Identifiable, Codable, Sendable {
    let id = UUID()
    let code: String
    let name: String
    let tsCode: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case code
        case name
        case tsCode = "ts_code"
        case createdAt = "created_at"
    }
}

/// 后端自选股列表响应
struct WatchlistResponse: Codable, Sendable {
    let items: [WatchlistItemData]
    let total: Int
}

/// 板块资金流数据
struct SectorMoneyflowData: Identifiable, Codable, Hashable, Sendable {
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
struct SectorMoneyflowRankResponse: Codable, Sendable {
    let sectors: [SectorMoneyflowData]
    let tradeDate: String
    let sectorType: String

    enum CodingKeys: String, CodingKey {
        case sectors
        case tradeDate = "trade_date"
        case sectorType = "sector_type"
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sectors = try container.decode([SectorMoneyflowData].self, forKey: .sectors)
        self.tradeDate = try container.decode(String.self, forKey: .tradeDate)
        self.sectorType = try container.decode(String.self, forKey: .sectorType)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sectors, forKey: .sectors)
        try container.encode(tradeDate, forKey: .tradeDate)
        try container.encode(sectorType, forKey: .sectorType)
    }
}

/// 板块资金流动态趋势响应
struct SectorMoneyflowTrendResponse: Codable, Sendable {
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

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sectorType = try container.decode(String.self, forKey: .sectorType)
        self.startDate = try container.decode(String.self, forKey: .startDate)
        self.endDate = try container.decode(String.self, forKey: .endDate)
        self.dates = try container.decode([String].self, forKey: .dates)
        self.series = try container.decode([SectorMoneyflowSeries].self, forKey: .series)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sectorType, forKey: .sectorType)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(dates, forKey: .dates)
        try container.encode(series, forKey: .series)
    }
}

/// 股票概念/题材归属
struct StockConcept: Identifiable, Codable, Hashable, Sendable {
    let id = UUID()
    let conceptId: String
    let conceptName: String
    let tsCode: String
    let name: String?
    let inDate: String?
    let outDate: String?

    enum CodingKeys: String, CodingKey {
        case conceptId = "concept_id"
        case conceptName = "concept_name"
        case tsCode = "ts_code"
        case name
        case inDate = "in_date"
        case outDate = "out_date"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(conceptId)
        hasher.combine(tsCode)
    }

    static func == (lhs: StockConcept, rhs: StockConcept) -> Bool {
        lhs.conceptId == rhs.conceptId && lhs.tsCode == rhs.tsCode
    }
}

/// 板块资金流趋势单条序列
struct SectorMoneyflowSeries: Identifiable, Codable, Sendable {
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
struct SectorMoneyflowTrendPoint: Codable, Sendable {
    let tradeDate: String
    let netAmount: Double
    let pctChange: Double?

    enum CodingKeys: String, CodingKey {
        case tradeDate = "trade_date"
        case netAmount = "net_amount"
        case pctChange = "pct_change"
    }
}

// MARK: - 涨停梯队

/// 涨停梯队响应
struct LimitUpLadderResponse: Codable, Sendable {
    let tradeDate: String
    let conceptTags: [LimitUpConceptTag]
    let ladder: [LimitUpLadderGroup]

    enum CodingKeys: String, CodingKey {
        case tradeDate = "trade_date"
        case conceptTags = "concept_tags"
        case ladder
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.tradeDate = try container.decode(String.self, forKey: .tradeDate)
        self.conceptTags = try container.decode([LimitUpConceptTag].self, forKey: .conceptTags)
        self.ladder = try container.decode([LimitUpLadderGroup].self, forKey: .ladder)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tradeDate, forKey: .tradeDate)
        try container.encode(conceptTags, forKey: .conceptTags)
        try container.encode(ladder, forKey: .ladder)
    }
}

/// 涨停概念标签
struct LimitUpConceptTag: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let count: Int
    let consCount: Int
    let pctChange: Double
    let rank: Int

    enum CodingKeys: String, CodingKey {
        case id = "concept_id"
        case name
        case count
        case consCount = "cons_count"
        case pctChange = "pct_change"
        case rank
    }

    init(id: String, name: String, count: Int, consCount: Int, pctChange: Double, rank: Int) {
        self.id = id
        self.name = name
        self.count = count
        self.consCount = consCount
        self.pctChange = pctChange
        self.rank = rank
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.name = try container.decode(String.self, forKey: .name)
        self.count = try container.decode(Int.self, forKey: .count)
        self.consCount = try container.decode(Int.self, forKey: .consCount)
        self.pctChange = try container.decode(Double.self, forKey: .pctChange)
        self.rank = try container.decode(Int.self, forKey: .rank)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(count, forKey: .count)
        try container.encode(consCount, forKey: .consCount)
        try container.encode(pctChange, forKey: .pctChange)
        try container.encode(rank, forKey: .rank)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: LimitUpConceptTag, rhs: LimitUpConceptTag) -> Bool {
        lhs.id == rhs.id
    }
}

/// 涨停梯队分组
struct LimitUpLadderGroup: Identifiable, Codable, Sendable {
    let id = UUID()
    let step: Int
    let label: String
    let stocks: [LimitUpLadderStock]
}

/// 涨停梯队个股
struct LimitUpLadderStock: Identifiable, Codable, Hashable, Sendable {
    let id = UUID()
    let tsCode: String
    let name: String
    let close: Double
    let pctChg: Double
    let firstTime: String?
    let lastTime: String?
    let openTimes: Int?
    let conceptTags: [String]?

    enum CodingKeys: String, CodingKey {
        case tsCode = "ts_code"
        case name
        case close
        case pctChg = "pct_chg"
        case firstTime = "first_time"
        case lastTime = "last_time"
        case openTimes = "open_times"
        case conceptTags = "concept_tags"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(tsCode)
    }

    static func == (lhs: LimitUpLadderStock, rhs: LimitUpLadderStock) -> Bool {
        lhs.tsCode == rhs.tsCode
    }
}

// MARK: - 公司基本信息（Tushare stock_company）

struct StockCompanyInfo: Identifiable, Codable, Sendable {
    let id = UUID()
    let tsCode: String
    let exchange: String?
    let chairman: String?
    let manager: String?
    let secretary: String?
    let regCapital: Double?
    let setupDate: String?
    let province: String?
    let city: String?
    let introduction: String?
    let website: String?
    let email: String?
    let office: String?
    let employees: Int?
    let mainBusiness: String?
    let businessScope: String?

    enum CodingKeys: String, CodingKey {
        case tsCode = "ts_code"
        case exchange
        case chairman
        case manager
        case secretary
        case regCapital = "reg_capital"
        case setupDate = "setup_date"
        case province
        case city
        case introduction
        case website
        case email
        case office
        case employees
        case mainBusiness = "main_business"
        case businessScope = "business_scope"
    }
}

// MARK: - 财务指标（Tushare fina_indicator）

struct FinaIndicator: Identifiable, Codable, Sendable {
    let id = UUID()
    let tsCode: String
    let annDate: String?
    let endDate: String?
    let eps: Double?
    let dtEps: Double?
    let bps: Double?
    let roe: Double?
    let roeYearly: Double?
    let roaYearly: Double?
    let netprofitMargin: Double?
    let grossprofitMargin: Double?
    let assetsTurn: Double?
    let debtToAssets: Double?
    let netprofitYoy: Double?
    let opYoy: Double?
    let bpsYoy: Double?

    enum CodingKeys: String, CodingKey {
        case tsCode = "ts_code"
        case annDate = "ann_date"
        case endDate = "end_date"
        case eps
        case dtEps = "dt_eps"
        case bps
        case roe
        case roeYearly = "roe_yearly"
        case roaYearly = "roa_yearly"
        case netprofitMargin = "netprofit_margin"
        case grossprofitMargin = "grossprofit_margin"
        case assetsTurn = "assets_turn"
        case debtToAssets = "debt_to_assets"
        case netprofitYoy = "netprofit_yoy"
        case opYoy = "op_yoy"
        case bpsYoy = "bps_yoy"
    }
}
