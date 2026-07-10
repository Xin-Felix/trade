import Foundation

// MARK: - 北向资金（沪深港通）

struct HsgtFlowData: Identifiable, Decodable {
    let id = UUID()
    let tradeDate: String
    let ggtSs: Double?      // 港股通（沪）
    let ggtSz: Double?      // 港股通（深）
    let hgt: Double?        // 沪股通
    let sgt: Double?        // 深股通
    let northMoney: Double? // 北向资金合计
    let southMoney: Double? // 南向资金合计

    enum CodingKeys: String, CodingKey {
        case tradeDate = "trade_date"
        case ggtSs = "ggt_ss"
        case ggtSz = "ggt_sz"
        case hgt
        case sgt
        case northMoney = "north_money"
        case southMoney = "south_money"
    }

    /// 格式化北向资金显示（万元转亿元）
    var northMoneyFormatted: String {
        guard let money = northMoney else { return "--" }
        return String(format: "%.1f亿", money / 10000.0)
    }

    /// 计算日变化（与前一天对比需要两条数据）
    func northChange(previous: HsgtFlowData?) -> Double? {
        guard let current = northMoney, let prev = previous?.northMoney else { return nil }
        return current - prev
    }
}

// MARK: - 龙虎榜明细

struct TopListItem: Identifiable, Decodable, Hashable {
    let id = UUID()
    let tradeDate: String
    let tsCode: String
    let name: String?
    let close: Double?
    let pctChange: Double?
    let turnoverRate: Double?
    let amount: Double?
    let netAmount: Double?
    let netRate: Double?
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case tradeDate = "trade_date"
        case tsCode = "ts_code"
        case name
        case close
        case pctChange = "pct_change"
        case turnoverRate = "turnover_rate"
        case amount
        case netAmount = "net_amount"
        case netRate = "net_rate"
        case reason
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(tsCode)
        hasher.combine(tradeDate)
    }

    static func == (lhs: TopListItem, rhs: TopListItem) -> Bool {
        lhs.tsCode == rhs.tsCode && lhs.tradeDate == rhs.tradeDate
    }

    /// 净买入金额格式化（万→亿）
    var netAmountFormatted: String {
        guard let amt = netAmount else { return "--" }
        if abs(amt) >= 100_000_000 {
            return String(format: "%.2f亿", amt / 100_000_000)
        } else if abs(amt) >= 10_000 {
            return String(format: "%.0f万", amt / 10_000)
        }
        return String(format: "%.0f", amt)
    }
}

// MARK: - 龙虎榜机构明细

struct TopInstItem: Identifiable, Decodable {
    let id = UUID()
    let tradeDate: String
    let tsCode: String
    let exalter: String?
    let buy: Double?
    let buyRate: Double?
    let sell: Double?
    let sellRate: Double?
    let netBuy: Double?
    let side: String?
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case tradeDate = "trade_date"
        case tsCode = "ts_code"
        case exalter
        case buy
        case buyRate = "buy_rate"
        case sell
        case sellRate = "sell_rate"
        case netBuy = "net_buy"
        case side
        case reason
    }
}

// MARK: - 指数日线

struct IndexDailyData: Identifiable, Decodable {
    let id = UUID()
    let tsCode: String
    let tradeDate: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let preClose: Double
    let change: Double
    let pctChg: Double
    let vol: Double?
    let amount: Double?

    enum CodingKeys: String, CodingKey {
        case tsCode = "ts_code"
        case tradeDate = "trade_date"
        case open
        case high
        case low
        case close
        case preClose = "pre_close"
        case change
        case pctChg = "pct_chg"
        case vol
        case amount
    }

    /// 成交额格式化（万→亿，接口已是千元单位）
    var amountFormatted: String {
        guard let amt = amount else { return "--" }
        return String(format: "%.0f亿", amt / 10000.0)
    }
}

// MARK: - 个股资金流

struct MoneyFlowData: Identifiable, Decodable {
    let id = UUID()
    let tsCode: String
    let tradeDate: String
    let buySmAmount: Double?    // 小单买入(万)
    let sellSmAmount: Double?   // 小单卖出(万)
    let buyMdAmount: Double?    // 中单买入(万)
    let sellMdAmount: Double?   // 中单卖出(万)
    let buyLgAmount: Double?    // 大单买入(万)
    let sellLgAmount: Double?   // 大单卖出(万)
    let buyElgAmount: Double?   // 特大单买入(万)
    let sellElgAmount: Double?  // 特大单卖出(万)
    let netMfAmount: Double?    // 净流入(万)

    enum CodingKeys: String, CodingKey {
        case tsCode = "ts_code"
        case tradeDate = "trade_date"
        case buySmAmount = "buy_sm_amount"
        case sellSmAmount = "sell_sm_amount"
        case buyMdAmount = "buy_md_amount"
        case sellMdAmount = "sell_md_amount"
        case buyLgAmount = "buy_lg_amount"
        case sellLgAmount = "sell_lg_amount"
        case buyElgAmount = "buy_elg_amount"
        case sellElgAmount = "sell_elg_amount"
        case netMfAmount = "net_mf_amount"
    }

    /// 主力净流入 = 大单 + 特大单
    var mainForceNet: Double {
        let buyLg = buyLgAmount ?? 0
        let sellLg = sellLgAmount ?? 0
        let buyElg = buyElgAmount ?? 0
        let sellElg = sellElgAmount ?? 0
        return (buyLg - sellLg) + (buyElg - sellElg)
    }

    var mainForceNetFormatted: String {
        let net = mainForceNet
        if abs(net) >= 10000 {
            return String(format: "%+.2f亿", net / 10000.0)
        }
        return String(format: "%+.0f万", net)
    }
}


// MARK: - 板块成分股

struct SectorMemberItem: Identifiable, Decodable {
    let id = UUID()
    let tsCode: String
    let conCode: String
    let conName: String?

    enum CodingKeys: String, CodingKey {
        case tsCode = "ts_code"
        case conCode = "con_code"
        case conName = "con_name"
    }
}
