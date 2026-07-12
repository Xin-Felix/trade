import SwiftUI

// MARK: - API 测试主视图

struct APITestView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("基础接口") {
                    NavigationLink("健康检查 GET /") {
                        APITestDetailView(test: .healthRoot)
                    }
                    NavigationLink("Health GET /health") {
                        APITestDetailView(test: .healthCheck)
                    }
                }

                Section("认证接口") {
                    NavigationLink("测试账号登录 POST /auth/login/email") {
                        APITestDetailView(test: .testLogin)
                    }
                    NavigationLink("发送验证码 POST /auth/email/code") {
                        APITestDetailView(test: .sendEmailCode)
                    }
                    NavigationLink("验证码登录 POST /auth/email/verify") {
                        APITestDetailView(test: .verifyEmailCode)
                    }
                }

                Section("股票行情") {
                    NavigationLink("单股行情 GET /stocks/quote/{code}") {
                        APITestDetailView(test: .stockQuote)
                    }
                    NavigationLink("K线数据 GET /stocks/klines/{code}") {
                        APITestDetailView(test: .stockKlines)
                    }
                    NavigationLink("分时K线 GET /stocks/intraday/{code}") {
                        APITestDetailView(test: .intradayKlines)
                    }
                    NavigationLink("大盘指数 GET /stocks/indices") {
                        APITestDetailView(test: .stockIndices)
                    }
                    NavigationLink("全球大盘 GET /stocks/global-indices") {
                        APITestDetailView(test: .globalIndices)
                    }
                    NavigationLink("指数日线 GET /stocks/index-daily/{code}") {
                        APITestDetailView(test: .indexDaily)
                    }
                    NavigationLink("股票搜索 GET /stocks/search") {
                        APITestDetailView(test: .stockSearch)
                    }
                    NavigationLink("股票列表 GET /stocks/basics") {
                        APITestDetailView(test: .stockBasics)
                    }
                    NavigationLink("日线因子 GET /stocks/daily-basic/{code}") {
                        APITestDetailView(test: .dailyBasic)
                    }
                    NavigationLink("涨跌停 GET /stocks/stock-limit") {
                        APITestDetailView(test: .stockLimit)
                    }
                }

                Section("资金流向") {
                    NavigationLink("板块资金流排行 GET /stocks/sector-moneyflow") {
                        APITestDetailView(test: .sectorMoneyflow)
                    }
                    NavigationLink("板块资金趋势 GET /stocks/sector-moneyflow/trend") {
                        APITestDetailView(test: .sectorMoneyflowTrend)
                    }
                    NavigationLink("个股资金流 GET /stocks/moneyflow/{code}") {
                        APITestDetailView(test: .stockMoneyflow)
                    }
                    NavigationLink("沪深港通 GET /stocks/moneyflow-hsgt") {
                        APITestDetailView(test: .moneyflowHsgt)
                    }
                }

                Section("龙虎榜") {
                    NavigationLink("龙虎榜明细 GET /stocks/top-list") {
                        APITestDetailView(test: .topList)
                    }
                    NavigationLink("龙虎榜机构 GET /stocks/top-inst") {
                        APITestDetailView(test: .topInst)
                    }
                }

                Section("同花顺指数") {
                    NavigationLink("指数列表 GET /stocks/ths-index") {
                        APITestDetailView(test: .thsIndex)
                    }
                    NavigationLink("指数日线 GET /stocks/ths-daily/{code}") {
                        APITestDetailView(test: .thsDaily)
                    }
                    NavigationLink("指数成分股 GET /stocks/ths-member/{code}") {
                        APITestDetailView(test: .thsMember)
                    }
                }

                Section("自选股") {
                    NavigationLink("自选股列表 GET /stocks/watchlist") {
                        APITestDetailView(test: .watchlist)
                    }
                    NavigationLink("股票概念/题材 GET /stocks/concepts/{code}") {
                        APITestDetailView(test: .stockConcepts)
                    }
                }

                // MARK: - Tushare 代理接口

                Section("财务数据 (Tushare)") {
                    NavigationLink("财务指标 GET /ts/fina-indicator/{code}") {
                        APITestDetailView(test: .tsFinaIndicator)
                    }
                    NavigationLink("利润表 GET /ts/income/{code}") {
                        APITestDetailView(test: .tsIncome)
                    }
                    NavigationLink("资产负债表 GET /ts/balancesheet/{code}") {
                        APITestDetailView(test: .tsBalancesheet)
                    }
                    NavigationLink("现金流量表 GET /ts/cashflow/{code}") {
                        APITestDetailView(test: .tsCashflow)
                    }
                    NavigationLink("业绩预告 GET /ts/forecast/{code}") {
                        APITestDetailView(test: .tsForecast)
                    }
                    NavigationLink("业绩快报 GET /ts/express/{code}") {
                        APITestDetailView(test: .tsExpress)
                    }
                    NavigationLink("分红送股 GET /ts/dividend/{code}") {
                        APITestDetailView(test: .tsDividend)
                    }
                }

                Section("股东数据 (Tushare)") {
                    NavigationLink("股东人数 GET /ts/holder-number/{code}") {
                        APITestDetailView(test: .tsHolderNumber)
                    }
                    NavigationLink("股东增减持 GET /ts/holder-trade/{code}") {
                        APITestDetailView(test: .tsHolderTrade)
                    }
                    NavigationLink("股权质押 GET /ts/pledge-stat/{code}") {
                        APITestDetailView(test: .tsPledgeStat)
                    }
                    NavigationLink("股票回购 GET /ts/repurchase/{code}") {
                        APITestDetailView(test: .tsRepurchase)
                    }
                }

                Section("交易数据 (Tushare)") {
                    NavigationLink("融资融券明细 GET /ts/margin/{code}") {
                        APITestDetailView(test: .tsMargin)
                    }
                    NavigationLink("融资融券汇总 GET /ts/margin-summary") {
                        APITestDetailView(test: .tsMarginSummary)
                    }
                    NavigationLink("大宗交易 GET /ts/block-trade") {
                        APITestDetailView(test: .tsBlockTrade)
                    }
                    NavigationLink("涨跌停统计 GET /ts/limit-list") {
                        APITestDetailView(test: .tsLimitList)
                    }
                }

                Section("技术面 (Tushare)") {
                    NavigationLink("技术因子 GET /ts/stk-factor/{code}") {
                        APITestDetailView(test: .tsStkFactor)
                    }
                    NavigationLink("筹码分布 GET /ts/cyq-perf/{code}") {
                        APITestDetailView(test: .tsCyqPerf)
                    }
                    NavigationLink("前复权行情 GET /ts/daily-adj/{code}") {
                        APITestDetailView(test: .tsDailyAdj)
                    }
                    NavigationLink("复权因子 GET /ts/adj-factor/{code}") {
                        APITestDetailView(test: .tsAdjFactor)
                    }
                    NavigationLink("停复牌 GET /ts/suspend/{code}") {
                        APITestDetailView(test: .tsSuspend)
                    }
                }

                Section("概念板块 (Tushare)") {
                    NavigationLink("概念列表 GET /ts/concept") {
                        APITestDetailView(test: .tsConcept)
                    }
                    NavigationLink("概念成分股 GET /ts/concept-detail/{id}") {
                        APITestDetailView(test: .tsConceptDetail)
                    }
                    NavigationLink("指数权重 GET /ts/index-weight/{code}") {
                        APITestDetailView(test: .tsIndexWeight)
                    }
                }

                Section("ETF基金 (Tushare)") {
                    NavigationLink("基金列表 GET /ts/fund-basic") {
                        APITestDetailView(test: .tsFundBasic)
                    }
                    NavigationLink("基金日线 GET /ts/fund-daily/{code}") {
                        APITestDetailView(test: .tsFundDaily)
                    }
                    NavigationLink("基金净值 GET /ts/fund-nav/{code}") {
                        APITestDetailView(test: .tsFundNav)
                    }
                }

                Section("新闻/日历 (Tushare)") {
                    NavigationLink("新闻快讯 GET /ts/news") {
                        APITestDetailView(test: .tsNews)
                    }
                    NavigationLink("交易日历 GET /ts/trade-cal") {
                        APITestDetailView(test: .tsTradeCal)
                    }
                }

                Section("数据同步") {
                    NavigationLink("增量同步 POST /sync/recent") {
                        APITestDetailView(test: .syncRecent)
                    }
                    NavigationLink("日K线同步 POST /sync/daily-kline") {
                        APITestDetailView(test: .syncDailyKline)
                    }
                    NavigationLink("日线因子同步 POST /sync/daily-basic") {
                        APITestDetailView(test: .syncDailyBasic)
                    }
                    NavigationLink("板块资金流同步 POST /sync/sector-moneyflow") {
                        APITestDetailView(test: .syncSectorMoneyflow)
                    }
                    NavigationLink("个股资金流同步 POST /sync/stock-moneyflow") {
                        APITestDetailView(test: .syncStockMoneyflow)
                    }
                    NavigationLink("指数日线同步 POST /sync/index-daily") {
                        APITestDetailView(test: .syncIndexDaily)
                    }
                    NavigationLink("沪深港通同步 POST /sync/hsgt") {
                        APITestDetailView(test: .syncHsgt)
                    }
                    NavigationLink("涨跌停同步 POST /sync/stock-limit") {
                        APITestDetailView(test: .syncStockLimit)
                    }
                    NavigationLink("概念板块同步 POST /sync/concept") {
                        APITestDetailView(test: .syncConcept)
                    }
                }

                Section("天气") {
                    NavigationLink("北京天气 GET /weather/beijing") {
                        APITestDetailView(test: .weatherBeijing)
                    }
                }
            }
            .navigationTitle("接口测试")
        }
    }
}

// MARK: - 测试用例枚举

enum APITestCase: String {
    // 基础
    case healthRoot
    case healthCheck
    // 认证
    case testLogin
    case sendEmailCode
    case verifyEmailCode
    // 股票行情
    case stockQuote
    case stockKlines
    case intradayKlines
    case stockIndices
    case globalIndices
    case indexDaily
    case stockSearch
    case stockBasics
    case dailyBasic
    case stockLimit
    // 资金流
    case sectorMoneyflow
    case sectorMoneyflowTrend
    case stockMoneyflow
    case moneyflowHsgt
    // 龙虎榜
    case topList
    case topInst
    // THS
    case thsIndex
    case thsDaily
    case thsMember
    // 自选
    case watchlist
    case stockConcepts
    // Tushare 代理 - 财务
    case tsFinaIndicator
    case tsIncome
    case tsBalancesheet
    case tsCashflow
    case tsForecast
    case tsExpress
    case tsDividend
    // Tushare 代理 - 股东
    case tsHolderNumber
    case tsHolderTrade
    case tsPledgeStat
    case tsRepurchase
    // Tushare 代理 - 交易
    case tsMargin
    case tsMarginSummary
    case tsBlockTrade
    case tsLimitList
    // Tushare 代理 - 技术面
    case tsStkFactor
    case tsCyqPerf
    case tsDailyAdj
    case tsAdjFactor
    case tsSuspend
    // Tushare 代理 - 概念板块
    case tsConcept
    case tsConceptDetail
    case tsIndexWeight
    // Tushare 代理 - ETF
    case tsFundBasic
    case tsFundDaily
    case tsFundNav
    // Tushare 代理 - 新闻/日历
    case tsNews
    case tsTradeCal
    // 数据同步
    case syncRecent
    case syncDailyKline
    case syncDailyBasic
    case syncSectorMoneyflow
    case syncStockMoneyflow
    case syncIndexDaily
    case syncHsgt
    case syncStockLimit
    case syncConcept
    // 天气
    case weatherBeijing

    var title: String {
        switch self {
        case .healthRoot: return "健康检查 /"
        case .healthCheck: return "Health /health"
        case .testLogin: return "测试账号登录"
        case .sendEmailCode: return "发送验证码"
        case .verifyEmailCode: return "验证码登录"
        case .stockQuote: return "单股行情"
        case .stockKlines: return "K线数据"
        case .intradayKlines: return "分时K线"
        case .stockIndices: return "大盘指数"
        case .globalIndices: return "全球大盘"
        case .indexDaily: return "指数日线"
        case .stockSearch: return "股票搜索"
        case .stockBasics: return "股票列表"
        case .dailyBasic: return "日线因子"
        case .stockLimit: return "涨跌停"
        case .sectorMoneyflow: return "板块资金流排行"
        case .sectorMoneyflowTrend: return "板块资金趋势"
        case .stockMoneyflow: return "个股资金流"
        case .moneyflowHsgt: return "沪深港通"
        case .topList: return "龙虎榜明细"
        case .topInst: return "龙虎榜机构"
        case .thsIndex: return "同花顺指数列表"
        case .thsDaily: return "同花顺指数日线"
        case .thsMember: return "同花顺成分股"
        case .watchlist: return "自选股列表"
        case .stockConcepts: return "股票概念/题材"
        case .tsFinaIndicator: return "财务指标"
        case .tsIncome: return "利润表"
        case .tsBalancesheet: return "资产负债表"
        case .tsCashflow: return "现金流量表"
        case .tsForecast: return "业绩预告"
        case .tsExpress: return "业绩快报"
        case .tsDividend: return "分红送股"
        case .tsHolderNumber: return "股东人数"
        case .tsHolderTrade: return "股东增减持"
        case .tsPledgeStat: return "股权质押"
        case .tsRepurchase: return "股票回购"
        case .tsMargin: return "融资融券明细"
        case .tsMarginSummary: return "融资融券汇总"
        case .tsBlockTrade: return "大宗交易"
        case .tsLimitList: return "涨跌停统计"
        case .tsStkFactor: return "技术因子"
        case .tsCyqPerf: return "筹码分布"
        case .tsDailyAdj: return "前复权行情"
        case .tsAdjFactor: return "复权因子"
        case .tsSuspend: return "停复牌"
        case .tsConcept: return "概念列表"
        case .tsConceptDetail: return "概念成分股"
        case .tsIndexWeight: return "指数权重"
        case .tsFundBasic: return "基金列表"
        case .tsFundDaily: return "基金日线"
        case .tsFundNav: return "基金净值"
        case .tsNews: return "新闻快讯"
        case .tsTradeCal: return "交易日历"
        case .syncRecent: return "增量同步"
        case .syncDailyKline: return "日K线同步"
        case .syncDailyBasic: return "日线因子同步"
        case .syncSectorMoneyflow: return "板块资金流同步"
        case .syncStockMoneyflow: return "个股资金流同步"
        case .syncIndexDaily: return "指数日线同步"
        case .syncHsgt: return "沪深港通同步"
        case .syncStockLimit: return "涨跌停同步"
        case .syncConcept: return "概念板块同步"
        case .weatherBeijing: return "北京天气"
        }
    }

    var method: String {
        switch self {
        case .testLogin, .sendEmailCode, .verifyEmailCode,
             .syncRecent, .syncDailyKline, .syncDailyBasic,
             .syncSectorMoneyflow, .syncStockMoneyflow,
             .syncIndexDaily, .syncHsgt, .syncStockLimit, .syncConcept:
            return "POST"
        default:
            return "GET"
        }
    }

    var needsAuth: Bool {
        switch self {
        case .healthRoot, .healthCheck, .testLogin, .sendEmailCode, .verifyEmailCode, .weatherBeijing:
            return false
        default:
            return true
        }
    }
}

// MARK: - 参数配置

struct APITestParam: Identifiable {
    let id = UUID()
    let key: String
    let placeholder: String
    var value: String
    let isRequired: Bool
}

// MARK: - 测试详情视图

struct APITestDetailView: View {
    let test: APITestCase

    @State private var params: [APITestParam] = []
    @State private var responseText: String = ""
    @State private var statusCode: Int?
    @State private var responseTime: TimeInterval?
    @State private var isLoading = false
    @State private var requestURL: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                infoSection
                paramsSection
                actionSection
                responseSection
            }
            .padding()
        }
        .navigationTitle(test.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { setupParams() }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(test.method)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(test.method == "POST" ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                    .foregroundStyle(test.method == "POST" ? .orange : .blue)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                if test.needsAuth {
                    Text("需登录")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.15))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Text("无需登录")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            if !requestURL.isEmpty {
                Text(requestURL)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var paramsSection: some View {
        Group {
            if !params.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("参数")
                        .font(.headline)

                    ForEach($params) { $param in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(param.key)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if param.isRequired {
                                    Text("*")
                                        .foregroundStyle(.red)
                                }
                            }
                            TextField(param.placeholder, text: $param.value)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var actionSection: some View {
        HStack(spacing: 12) {
            Button {
                Task { await executeRequest() }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }
                    Text("发送请求")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isLoading)

            if !responseText.isEmpty {
                Button {
                    responseText = ""
                    statusCode = nil
                    responseTime = nil
                } label: {
                    Text("清除")
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var responseSection: some View {
        Group {
            if !responseText.isEmpty || statusCode != nil {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("响应")
                            .font(.headline)

                        Spacer()

                        if let statusCode {
                            Text("HTTP \(statusCode)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusCodeColor.opacity(0.15))
                                .foregroundStyle(statusCodeColor)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        if let responseTime {
                            Text(String(format: "%.0fms", responseTime * 1000))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(responseText)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var statusCodeColor: Color {
        guard let code = statusCode else { return .secondary }
        switch code {
        case 200..<300: return .green
        case 400..<500: return .orange
        default: return .red
        }
    }

    // MARK: - Setup

    private func setupParams() {
        switch test {
        case .healthRoot, .healthCheck, .stockIndices, .globalIndices, .watchlist, .weatherBeijing, .stockBasics, .syncConcept:
            params = []
        case .stockConcepts:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true)
            ]
        case .testLogin:
            params = [
                APITestParam(key: "email", placeholder: "1538933906@qq.com", value: "1538933906@qq.com", isRequired: true),
                APITestParam(key: "password", placeholder: "123456", value: "123456", isRequired: true)
            ]
        case .sendEmailCode:
            params = [
                APITestParam(key: "email", placeholder: "user@example.com", value: "1538933906@qq.com", isRequired: true),
                APITestParam(key: "purpose", placeholder: "login", value: "login", isRequired: false)
            ]
        case .verifyEmailCode:
            params = [
                APITestParam(key: "email", placeholder: "user@example.com", value: "1538933906@qq.com", isRequired: true),
                APITestParam(key: "code", placeholder: "123456", value: "", isRequired: true),
                APITestParam(key: "purpose", placeholder: "login", value: "login", isRequired: false)
            ]
        case .stockQuote:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true)
            ]
        case .stockKlines:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "period", placeholder: "D/W/M/Y", value: "D", isRequired: false),
                APITestParam(key: "limit", placeholder: "30", value: "30", isRequired: false)
            ]
        case .intradayKlines:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "period", placeholder: "1/5/15/30/60", value: "1", isRequired: false),
                APITestParam(key: "limit", placeholder: "240", value: "240", isRequired: false)
            ]
        case .indexDaily:
            params = [
                APITestParam(key: "code", placeholder: "000001.SH", value: "000001.SH", isRequired: true),
                APITestParam(key: "limit", placeholder: "30", value: "30", isRequired: false)
            ]
        case .stockSearch:
            params = [
                APITestParam(key: "q", placeholder: "平安/000001/pa", value: "平安", isRequired: true),
                APITestParam(key: "limit", placeholder: "10", value: "10", isRequired: false)
            ]
        case .dailyBasic:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "limit", placeholder: "30", value: "1", isRequired: false)
            ]
        case .stockLimit:
            params = [
                APITestParam(key: "trade_date", placeholder: "YYYYMMDD（留空取最新）", value: todayDate(), isRequired: false),
                APITestParam(key: "limit", placeholder: "100", value: "20", isRequired: false)
            ]
        case .sectorMoneyflow:
            params = [
                APITestParam(key: "sector_type", placeholder: "industry/concept", value: "industry", isRequired: false),
                APITestParam(key: "trade_date", placeholder: "YYYYMMDD", value: "", isRequired: false),
                APITestParam(key: "sort_by", placeholder: "net_amount/pct_change/net_amount_asc", value: "net_amount", isRequired: false),
                APITestParam(key: "limit", placeholder: "20", value: "20", isRequired: false)
            ]
        case .sectorMoneyflowTrend:
            params = [
                APITestParam(key: "sector_type", placeholder: "industry/concept", value: "industry", isRequired: false),
                APITestParam(key: "start_date", placeholder: "YYYYMMDD", value: recentStartDate(), isRequired: true),
                APITestParam(key: "end_date", placeholder: "YYYYMMDD", value: todayDate(), isRequired: true),
                APITestParam(key: "top_n", placeholder: "30", value: "10", isRequired: false)
            ]
        case .stockMoneyflow:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "limit", placeholder: "30", value: "10", isRequired: false)
            ]
        case .moneyflowHsgt:
            params = [
                APITestParam(key: "start_date", placeholder: "YYYYMMDD", value: recentStartDate(), isRequired: false),
                APITestParam(key: "end_date", placeholder: "YYYYMMDD", value: todayDate(), isRequired: false),
                APITestParam(key: "limit", placeholder: "30", value: "10", isRequired: false)
            ]
        case .topList:
            params = [
                APITestParam(key: "trade_date", placeholder: "YYYYMMDD", value: todayDate(), isRequired: false),
                APITestParam(key: "limit", placeholder: "100", value: "20", isRequired: false)
            ]
        case .topInst:
            params = [
                APITestParam(key: "trade_date", placeholder: "YYYYMMDD", value: todayDate(), isRequired: false),
                APITestParam(key: "code", placeholder: "股票代码（可选）", value: "000001.SZ", isRequired: false),
                APITestParam(key: "limit", placeholder: "100", value: "20", isRequired: false)
            ]
        case .thsIndex:
            params = [
                APITestParam(key: "limit", placeholder: "1000", value: "20", isRequired: false)
            ]
        case .thsDaily:
            params = [
                APITestParam(key: "code", placeholder: "885760.TI", value: "885760.TI", isRequired: true),
                APITestParam(key: "limit", placeholder: "30", value: "30", isRequired: false)
            ]
        case .thsMember:
            params = [
                APITestParam(key: "code", placeholder: "885760.TI", value: "885760.TI", isRequired: true),
                APITestParam(key: "limit", placeholder: "1000", value: "20", isRequired: false)
            ]
        // Tushare 代理 - 财务
        case .tsFinaIndicator:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "limit", placeholder: "8", value: "4", isRequired: false)
            ]
        case .tsIncome:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "limit", placeholder: "8", value: "4", isRequired: false)
            ]
        case .tsBalancesheet:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "limit", placeholder: "8", value: "4", isRequired: false)
            ]
        case .tsCashflow:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "limit", placeholder: "8", value: "4", isRequired: false)
            ]
        case .tsForecast:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "limit", placeholder: "5", value: "5", isRequired: false)
            ]
        case .tsExpress:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "limit", placeholder: "5", value: "5", isRequired: false)
            ]
        case .tsDividend:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "limit", placeholder: "10", value: "5", isRequired: false)
            ]
        // Tushare 代理 - 股东
        case .tsHolderNumber:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "limit", placeholder: "10", value: "5", isRequired: false)
            ]
        case .tsHolderTrade:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "limit", placeholder: "20", value: "10", isRequired: false)
            ]
        case .tsPledgeStat:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "limit", placeholder: "10", value: "5", isRequired: false)
            ]
        case .tsRepurchase:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "limit", placeholder: "20", value: "10", isRequired: false)
            ]
        // Tushare 代理 - 交易
        case .tsMargin:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "start_date", placeholder: "YYYYMMDD", value: recentStartDate(), isRequired: false),
                APITestParam(key: "end_date", placeholder: "YYYYMMDD", value: todayDate(), isRequired: false),
                APITestParam(key: "limit", placeholder: "30", value: "10", isRequired: false)
            ]
        case .tsMarginSummary:
            params = [
                APITestParam(key: "trade_date", placeholder: "YYYYMMDD", value: todayDate(), isRequired: false),
                APITestParam(key: "start_date", placeholder: "YYYYMMDD", value: "", isRequired: false),
                APITestParam(key: "end_date", placeholder: "YYYYMMDD", value: "", isRequired: false),
                APITestParam(key: "limit", placeholder: "30", value: "10", isRequired: false)
            ]
        case .tsBlockTrade:
            params = [
                APITestParam(key: "code", placeholder: "股票代码（可选）", value: "", isRequired: false),
                APITestParam(key: "trade_date", placeholder: "YYYYMMDD", value: todayDate(), isRequired: false),
                APITestParam(key: "start_date", placeholder: "YYYYMMDD", value: "", isRequired: false),
                APITestParam(key: "end_date", placeholder: "YYYYMMDD", value: "", isRequired: false),
                APITestParam(key: "limit", placeholder: "50", value: "20", isRequired: false)
            ]
        case .tsLimitList:
            params = [
                APITestParam(key: "trade_date", placeholder: "YYYYMMDD", value: todayDate(), isRequired: false),
                APITestParam(key: "limit_type", placeholder: "U涨停/D跌停/Z炸板", value: "U", isRequired: false),
                APITestParam(key: "limit", placeholder: "100", value: "30", isRequired: false)
            ]
        // Tushare 代理 - 技术面
        case .tsStkFactor:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "start_date", placeholder: "YYYYMMDD", value: recentStartDate(), isRequired: false),
                APITestParam(key: "end_date", placeholder: "YYYYMMDD", value: todayDate(), isRequired: false),
                APITestParam(key: "limit", placeholder: "30", value: "10", isRequired: false)
            ]
        case .tsCyqPerf:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "start_date", placeholder: "YYYYMMDD", value: recentStartDate(), isRequired: false),
                APITestParam(key: "end_date", placeholder: "YYYYMMDD", value: todayDate(), isRequired: false),
                APITestParam(key: "limit", placeholder: "30", value: "10", isRequired: false)
            ]
        case .tsDailyAdj:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "start_date", placeholder: "YYYYMMDD", value: recentStartDate(), isRequired: false),
                APITestParam(key: "end_date", placeholder: "YYYYMMDD", value: todayDate(), isRequired: false),
                APITestParam(key: "limit", placeholder: "60", value: "30", isRequired: false)
            ]
        case .tsAdjFactor:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "limit", placeholder: "30", value: "10", isRequired: false)
            ]
        case .tsSuspend:
            params = [
                APITestParam(key: "code", placeholder: "000001", value: "000001", isRequired: true),
                APITestParam(key: "start_date", placeholder: "YYYYMMDD", value: "", isRequired: false),
                APITestParam(key: "end_date", placeholder: "YYYYMMDD", value: "", isRequired: false),
                APITestParam(key: "limit", placeholder: "30", value: "10", isRequired: false)
            ]
        // Tushare 代理 - 概念板块
        case .tsConcept:
            params = [
                APITestParam(key: "limit", placeholder: "500", value: "30", isRequired: false)
            ]
        case .tsConceptDetail:
            params = [
                APITestParam(key: "concept_id", placeholder: "885760.TI", value: "885760.TI", isRequired: true),
                APITestParam(key: "limit", placeholder: "200", value: "20", isRequired: false)
            ]
        case .tsIndexWeight:
            params = [
                APITestParam(key: "code", placeholder: "000300.SH", value: "000300.SH", isRequired: true),
                APITestParam(key: "trade_date", placeholder: "YYYYMMDD", value: "", isRequired: false),
                APITestParam(key: "limit", placeholder: "100", value: "30", isRequired: false)
            ]
        // Tushare 代理 - ETF
        case .tsFundBasic:
            params = [
                APITestParam(key: "market", placeholder: "E场内/O场外", value: "E", isRequired: false),
                APITestParam(key: "limit", placeholder: "100", value: "30", isRequired: false)
            ]
        case .tsFundDaily:
            params = [
                APITestParam(key: "code", placeholder: "510300.SH", value: "510300.SH", isRequired: true),
                APITestParam(key: "start_date", placeholder: "YYYYMMDD", value: recentStartDate(), isRequired: false),
                APITestParam(key: "end_date", placeholder: "YYYYMMDD", value: todayDate(), isRequired: false),
                APITestParam(key: "limit", placeholder: "30", value: "30", isRequired: false)
            ]
        case .tsFundNav:
            params = [
                APITestParam(key: "code", placeholder: "510300.SH", value: "510300.SH", isRequired: true),
                APITestParam(key: "limit", placeholder: "30", value: "10", isRequired: false)
            ]
        // Tushare 代理 - 新闻/日历
        case .tsNews:
            params = [
                APITestParam(key: "src", placeholder: "sina/wallstreetcn/10jqka/eastmoney", value: "sina", isRequired: false),
                APITestParam(key: "start_date", placeholder: "YYYY-MM-DD HH:MM:SS", value: "", isRequired: false),
                APITestParam(key: "end_date", placeholder: "YYYY-MM-DD HH:MM:SS", value: "", isRequired: false),
                APITestParam(key: "limit", placeholder: "50", value: "20", isRequired: false)
            ]
        case .tsTradeCal:
            params = [
                APITestParam(key: "start_date", placeholder: "YYYYMMDD", value: todayDate(), isRequired: false),
                APITestParam(key: "end_date", placeholder: "YYYYMMDD", value: "", isRequired: false),
                APITestParam(key: "is_open", placeholder: "0休市/1交易/留空全部", value: "", isRequired: false),
                APITestParam(key: "limit", placeholder: "60", value: "30", isRequired: false)
            ]
        // 数据同步
        case .syncRecent:
            params = [
                APITestParam(key: "days", placeholder: "3", value: "3", isRequired: false)
            ]
        case .syncDailyKline:
            params = [
                APITestParam(key: "days", placeholder: "1", value: "1", isRequired: false)
            ]
        case .syncDailyBasic:
            params = [
                APITestParam(key: "days", placeholder: "1", value: "1", isRequired: false)
            ]
        case .syncSectorMoneyflow:
            params = [
                APITestParam(key: "sector_type", placeholder: "industry/concept", value: "industry", isRequired: false),
                APITestParam(key: "days", placeholder: "3", value: "3", isRequired: false)
            ]
        case .syncStockMoneyflow:
            params = [
                APITestParam(key: "days", placeholder: "3", value: "3", isRequired: false)
            ]
        case .syncIndexDaily:
            params = [
                APITestParam(key: "days", placeholder: "3", value: "3", isRequired: false)
            ]
        case .syncHsgt:
            params = [
                APITestParam(key: "days", placeholder: "3", value: "3", isRequired: false)
            ]
        case .syncStockLimit:
            params = [
                APITestParam(key: "days", placeholder: "3", value: "3", isRequired: false)
            ]
        }
        updateRequestURL()
    }

    // MARK: - Request

    private func executeRequest() async {
        isLoading = true
        responseText = ""
        statusCode = nil
        responseTime = nil
        updateRequestURL()

        let startTime = Date()

        do {
            let (data, response) = try await makeRawRequest()
            let elapsed = Date().timeIntervalSince(startTime)
            responseTime = elapsed

            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
            }

            if let json = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                responseText = prettyString
            } else {
                responseText = String(data: data, encoding: .utf8) ?? "(无法解析响应)"
            }
        } catch {
            responseText = "请求失败: \(error.localizedDescription)"
            responseTime = Date().timeIntervalSince(startTime)
        }

        isLoading = false
    }

    private func makeRawRequest() async throws -> (Data, URLResponse) {
        let baseURL = APIConfiguration.shared.apiV1URL
        var urlString: String
        var httpMethod = "GET"
        var bodyData: Data?

        switch test {
        case .healthRoot:
            urlString = APIConfiguration.shared.baseURL + "/"
        case .healthCheck:
            urlString = APIConfiguration.shared.baseURL + "/health"
        case .testLogin:
            urlString = baseURL + "/auth/login/email"
            httpMethod = "POST"
            let body: [String: String] = [
                "email": paramValue("email"),
                "password": paramValue("password")
            ]
            bodyData = try JSONSerialization.data(withJSONObject: body)
        case .sendEmailCode:
            urlString = baseURL + "/auth/email/code"
            httpMethod = "POST"
            var body: [String: String] = ["email": paramValue("email")]
            let purpose = paramValue("purpose")
            if !purpose.isEmpty { body["purpose"] = purpose }
            bodyData = try JSONSerialization.data(withJSONObject: body)
        case .verifyEmailCode:
            urlString = baseURL + "/auth/email/verify"
            httpMethod = "POST"
            var body: [String: String] = [
                "email": paramValue("email"),
                "code": paramValue("code")
            ]
            let purpose = paramValue("purpose")
            if !purpose.isEmpty { body["purpose"] = purpose }
            bodyData = try JSONSerialization.data(withJSONObject: body)
        case .stockQuote:
            urlString = baseURL + "/stocks/quote/\(paramValue("code"))"
        case .stockKlines:
            urlString = buildURL(baseURL + "/stocks/klines/\(paramValue("code"))", queryKeys: ["period", "limit"])
        case .intradayKlines:
            urlString = buildURL(baseURL + "/stocks/intraday/\(paramValue("code"))", queryKeys: ["period", "limit"])
        case .stockIndices:
            urlString = baseURL + "/stocks/indices"
        case .globalIndices:
            urlString = baseURL + "/stocks/global-indices"
        case .indexDaily:
            urlString = buildURL(baseURL + "/stocks/index-daily/\(paramValue("code"))", queryKeys: ["limit"])
        case .stockSearch:
            urlString = buildURL(baseURL + "/stocks/search", queryKeys: ["q", "limit"])
        case .stockBasics:
            urlString = baseURL + "/stocks/basics"
        case .dailyBasic:
            urlString = buildURL(baseURL + "/stocks/daily-basic/\(paramValue("code"))", queryKeys: ["limit"])
        case .stockLimit:
            urlString = buildURL(baseURL + "/stocks/stock-limit", queryKeys: ["trade_date", "limit"])
        case .sectorMoneyflow:
            urlString = buildURL(baseURL + "/stocks/sector-moneyflow", queryKeys: ["sector_type", "trade_date", "sort_by", "limit"])
        case .sectorMoneyflowTrend:
            urlString = buildURL(baseURL + "/stocks/sector-moneyflow/trend", queryKeys: ["sector_type", "start_date", "end_date", "top_n"])
        case .stockMoneyflow:
            urlString = buildURL(baseURL + "/stocks/moneyflow/\(paramValue("code"))", queryKeys: ["limit"])
        case .moneyflowHsgt:
            urlString = buildURL(baseURL + "/stocks/moneyflow-hsgt", queryKeys: ["start_date", "end_date", "limit"])
        case .topList:
            urlString = buildURL(baseURL + "/stocks/top-list", queryKeys: ["trade_date", "limit"])
        case .topInst:
            urlString = buildURL(baseURL + "/stocks/top-inst", queryKeys: ["trade_date", "code", "limit"])
        case .thsIndex:
            urlString = buildURL(baseURL + "/stocks/ths-index", queryKeys: ["limit"])
        case .thsDaily:
            urlString = buildURL(baseURL + "/stocks/ths-daily/\(paramValue("code"))", queryKeys: ["limit"])
        case .thsMember:
            urlString = buildURL(baseURL + "/stocks/ths-member/\(paramValue("code"))", queryKeys: ["limit"])
        case .watchlist:
            urlString = baseURL + "/stocks/watchlist"
        case .stockConcepts:
            urlString = baseURL + "/stocks/concepts/\(paramValue("code"))"
        // Tushare 代理
        case .tsFinaIndicator:
            urlString = buildURL(baseURL + "/ts/fina-indicator/\(paramValue("code"))", queryKeys: ["limit"])
        case .tsIncome:
            urlString = buildURL(baseURL + "/ts/income/\(paramValue("code"))", queryKeys: ["limit"])
        case .tsBalancesheet:
            urlString = buildURL(baseURL + "/ts/balancesheet/\(paramValue("code"))", queryKeys: ["limit"])
        case .tsCashflow:
            urlString = buildURL(baseURL + "/ts/cashflow/\(paramValue("code"))", queryKeys: ["limit"])
        case .tsForecast:
            urlString = buildURL(baseURL + "/ts/forecast/\(paramValue("code"))", queryKeys: ["limit"])
        case .tsExpress:
            urlString = buildURL(baseURL + "/ts/express/\(paramValue("code"))", queryKeys: ["limit"])
        case .tsDividend:
            urlString = buildURL(baseURL + "/ts/dividend/\(paramValue("code"))", queryKeys: ["limit"])
        case .tsHolderNumber:
            urlString = buildURL(baseURL + "/ts/holder-number/\(paramValue("code"))", queryKeys: ["limit"])
        case .tsHolderTrade:
            urlString = buildURL(baseURL + "/ts/holder-trade/\(paramValue("code"))", queryKeys: ["limit"])
        case .tsPledgeStat:
            urlString = buildURL(baseURL + "/ts/pledge-stat/\(paramValue("code"))", queryKeys: ["limit"])
        case .tsRepurchase:
            urlString = buildURL(baseURL + "/ts/repurchase/\(paramValue("code"))", queryKeys: ["limit"])
        case .tsMargin:
            urlString = buildURL(baseURL + "/ts/margin/\(paramValue("code"))", queryKeys: ["start_date", "end_date", "limit"])
        case .tsMarginSummary:
            urlString = buildURL(baseURL + "/ts/margin-summary", queryKeys: ["trade_date", "start_date", "end_date", "limit"])
        case .tsBlockTrade:
            urlString = buildURL(baseURL + "/ts/block-trade", queryKeys: ["code", "trade_date", "start_date", "end_date", "limit"])
        case .tsLimitList:
            urlString = buildURL(baseURL + "/ts/limit-list", queryKeys: ["trade_date", "limit_type", "limit"])
        case .tsStkFactor:
            urlString = buildURL(baseURL + "/ts/stk-factor/\(paramValue("code"))", queryKeys: ["start_date", "end_date", "limit"])
        case .tsCyqPerf:
            urlString = buildURL(baseURL + "/ts/cyq-perf/\(paramValue("code"))", queryKeys: ["start_date", "end_date", "limit"])
        case .tsDailyAdj:
            urlString = buildURL(baseURL + "/ts/daily-adj/\(paramValue("code"))", queryKeys: ["start_date", "end_date", "limit"])
        case .tsAdjFactor:
            urlString = buildURL(baseURL + "/ts/adj-factor/\(paramValue("code"))", queryKeys: ["limit"])
        case .tsSuspend:
            urlString = buildURL(baseURL + "/ts/suspend/\(paramValue("code"))", queryKeys: ["start_date", "end_date", "limit"])
        case .tsConcept:
            urlString = buildURL(baseURL + "/ts/concept", queryKeys: ["limit"])
        case .tsConceptDetail:
            urlString = buildURL(baseURL + "/ts/concept-detail/\(paramValue("concept_id"))", queryKeys: ["limit"])
        case .tsIndexWeight:
            urlString = buildURL(baseURL + "/ts/index-weight/\(paramValue("code"))", queryKeys: ["trade_date", "limit"])
        case .tsFundBasic:
            urlString = buildURL(baseURL + "/ts/fund-basic", queryKeys: ["market", "limit"])
        case .tsFundDaily:
            urlString = buildURL(baseURL + "/ts/fund-daily/\(paramValue("code"))", queryKeys: ["start_date", "end_date", "limit"])
        case .tsFundNav:
            urlString = buildURL(baseURL + "/ts/fund-nav/\(paramValue("code"))", queryKeys: ["limit"])
        case .tsNews:
            urlString = buildURL(baseURL + "/ts/news", queryKeys: ["src", "start_date", "end_date", "limit"])
        case .tsTradeCal:
            urlString = buildURL(baseURL + "/ts/trade-cal", queryKeys: ["start_date", "end_date", "is_open", "limit"])
        // 数据同步
        case .syncRecent:
            urlString = buildURL(baseURL + "/sync/recent", queryKeys: ["days"])
            httpMethod = "POST"
        case .syncDailyKline:
            urlString = buildURL(baseURL + "/sync/daily-kline", queryKeys: ["days"])
            httpMethod = "POST"
        case .syncDailyBasic:
            urlString = buildURL(baseURL + "/sync/daily-basic", queryKeys: ["days"])
            httpMethod = "POST"
        case .syncSectorMoneyflow:
            urlString = buildURL(baseURL + "/sync/sector-moneyflow", queryKeys: ["sector_type", "days"])
            httpMethod = "POST"
        case .syncStockMoneyflow:
            urlString = buildURL(baseURL + "/sync/stock-moneyflow", queryKeys: ["days"])
            httpMethod = "POST"
        case .syncIndexDaily:
            urlString = buildURL(baseURL + "/sync/index-daily", queryKeys: ["days"])
            httpMethod = "POST"
        case .syncHsgt:
            urlString = buildURL(baseURL + "/sync/hsgt", queryKeys: ["days"])
            httpMethod = "POST"
        case .syncStockLimit:
            urlString = buildURL(baseURL + "/sync/stock-limit", queryKeys: ["days"])
            httpMethod = "POST"
        case .syncConcept:
            urlString = baseURL + "/sync/concept"
            httpMethod = "POST"
        case .weatherBeijing:
            urlString = baseURL + "/weather/beijing"
        }

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.timeoutInterval = APIConfiguration.shared.timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // 注入 Token（只要已登录就带上，避免需要认证的接口 401）
        if let token = NetworkService.shared.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let bodyData {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData
        }

        requestURL = urlString
        return try await URLSession.shared.data(for: request)
    }

    // MARK: - Helpers

    /// 构建带 query 参数的 URL，自动跳过空值
    private func buildURL(_ base: String, queryKeys: [String]) -> String {
        var components = URLComponents(string: base)!
        var queryItems: [URLQueryItem] = []
        for key in queryKeys {
            let value = paramValue(key)
            if !value.isEmpty {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        return components.url?.absoluteString ?? base
    }

    private func paramValue(_ key: String) -> String {
        params.first(where: { $0.key == key })?.value.trimmingCharacters(in: .whitespaces) ?? ""
    }

    private func updateRequestURL() {
        // 简单展示当前 URL（用于 info section 显示）
        let baseURL = APIConfiguration.shared.apiV1URL
        switch test {
        case .healthRoot:
            requestURL = APIConfiguration.shared.baseURL + "/"
        case .healthCheck:
            requestURL = APIConfiguration.shared.baseURL + "/health"
        case .testLogin:
            requestURL = baseURL + "/auth/login/email"
        case .sendEmailCode:
            requestURL = baseURL + "/auth/email/code"
        case .verifyEmailCode:
            requestURL = baseURL + "/auth/email/verify"
        case .stockQuote:
            requestURL = baseURL + "/stocks/quote/\(paramValue("code"))"
        case .stockKlines:
            requestURL = baseURL + "/stocks/klines/\(paramValue("code"))"
        case .intradayKlines:
            requestURL = baseURL + "/stocks/intraday/\(paramValue("code"))"
        case .stockIndices:
            requestURL = baseURL + "/stocks/indices"
        case .globalIndices:
            requestURL = baseURL + "/stocks/global-indices"
        case .indexDaily:
            requestURL = baseURL + "/stocks/index-daily/\(paramValue("code"))"
        case .stockSearch:
            requestURL = baseURL + "/stocks/search?q=\(paramValue("q"))"
        case .stockBasics:
            requestURL = baseURL + "/stocks/basics"
        case .dailyBasic:
            requestURL = baseURL + "/stocks/daily-basic/\(paramValue("code"))"
        case .stockLimit:
            requestURL = baseURL + "/stocks/stock-limit"
        case .sectorMoneyflow:
            requestURL = baseURL + "/stocks/sector-moneyflow"
        case .sectorMoneyflowTrend:
            requestURL = baseURL + "/stocks/sector-moneyflow/trend"
        case .stockMoneyflow:
            requestURL = baseURL + "/stocks/moneyflow/\(paramValue("code"))"
        case .moneyflowHsgt:
            requestURL = baseURL + "/stocks/moneyflow-hsgt"
        case .topList:
            requestURL = baseURL + "/stocks/top-list"
        case .topInst:
            requestURL = baseURL + "/stocks/top-inst"
        case .thsIndex:
            requestURL = baseURL + "/stocks/ths-index"
        case .thsDaily:
            requestURL = baseURL + "/stocks/ths-daily/\(paramValue("code"))"
        case .thsMember:
            requestURL = baseURL + "/stocks/ths-member/\(paramValue("code"))"
        case .watchlist:
            requestURL = baseURL + "/stocks/watchlist"
        case .stockConcepts:
            requestURL = baseURL + "/stocks/concepts/\(paramValue("code"))"
        // Tushare 代理
        case .tsFinaIndicator:
            requestURL = baseURL + "/ts/fina-indicator/\(paramValue("code"))"
        case .tsIncome:
            requestURL = baseURL + "/ts/income/\(paramValue("code"))"
        case .tsBalancesheet:
            requestURL = baseURL + "/ts/balancesheet/\(paramValue("code"))"
        case .tsCashflow:
            requestURL = baseURL + "/ts/cashflow/\(paramValue("code"))"
        case .tsForecast:
            requestURL = baseURL + "/ts/forecast/\(paramValue("code"))"
        case .tsExpress:
            requestURL = baseURL + "/ts/express/\(paramValue("code"))"
        case .tsDividend:
            requestURL = baseURL + "/ts/dividend/\(paramValue("code"))"
        case .tsHolderNumber:
            requestURL = baseURL + "/ts/holder-number/\(paramValue("code"))"
        case .tsHolderTrade:
            requestURL = baseURL + "/ts/holder-trade/\(paramValue("code"))"
        case .tsPledgeStat:
            requestURL = baseURL + "/ts/pledge-stat/\(paramValue("code"))"
        case .tsRepurchase:
            requestURL = baseURL + "/ts/repurchase/\(paramValue("code"))"
        case .tsMargin:
            requestURL = baseURL + "/ts/margin/\(paramValue("code"))"
        case .tsMarginSummary:
            requestURL = baseURL + "/ts/margin-summary"
        case .tsBlockTrade:
            requestURL = baseURL + "/ts/block-trade"
        case .tsLimitList:
            requestURL = baseURL + "/ts/limit-list"
        case .tsStkFactor:
            requestURL = baseURL + "/ts/stk-factor/\(paramValue("code"))"
        case .tsCyqPerf:
            requestURL = baseURL + "/ts/cyq-perf/\(paramValue("code"))"
        case .tsDailyAdj:
            requestURL = baseURL + "/ts/daily-adj/\(paramValue("code"))"
        case .tsAdjFactor:
            requestURL = baseURL + "/ts/adj-factor/\(paramValue("code"))"
        case .tsSuspend:
            requestURL = baseURL + "/ts/suspend/\(paramValue("code"))"
        case .tsConcept:
            requestURL = baseURL + "/ts/concept"
        case .tsConceptDetail:
            requestURL = baseURL + "/ts/concept-detail/\(paramValue("concept_id"))"
        case .tsIndexWeight:
            requestURL = baseURL + "/ts/index-weight/\(paramValue("code"))"
        case .tsFundBasic:
            requestURL = baseURL + "/ts/fund-basic"
        case .tsFundDaily:
            requestURL = baseURL + "/ts/fund-daily/\(paramValue("code"))"
        case .tsFundNav:
            requestURL = baseURL + "/ts/fund-nav/\(paramValue("code"))"
        case .tsNews:
            requestURL = baseURL + "/ts/news"
        case .tsTradeCal:
            requestURL = baseURL + "/ts/trade-cal"
        // 数据同步
        case .syncRecent:
            requestURL = baseURL + "/sync/recent?days=\(paramValue("days"))"
        case .syncDailyKline:
            requestURL = baseURL + "/sync/daily-kline?days=\(paramValue("days"))"
        case .syncDailyBasic:
            requestURL = baseURL + "/sync/daily-basic?days=\(paramValue("days"))"
        case .syncSectorMoneyflow:
            requestURL = baseURL + "/sync/sector-moneyflow"
        case .syncStockMoneyflow:
            requestURL = baseURL + "/sync/stock-moneyflow?days=\(paramValue("days"))"
        case .syncIndexDaily:
            requestURL = baseURL + "/sync/index-daily?days=\(paramValue("days"))"
        case .syncHsgt:
            requestURL = baseURL + "/sync/hsgt?days=\(paramValue("days"))"
        case .syncStockLimit:
            requestURL = baseURL + "/sync/stock-limit?days=\(paramValue("days"))"
        case .syncConcept:
            requestURL = baseURL + "/sync/concept"
        case .weatherBeijing:
            requestURL = baseURL + "/weather/beijing"
        }
    }

    private func todayDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }

    private func recentStartDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return formatter.string(from: sevenDaysAgo)
    }
}

// MARK: - Preview

#Preview {
    APITestView()
}
