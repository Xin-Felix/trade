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
    case healthRoot
    case healthCheck
    case testLogin
    case sendEmailCode
    case verifyEmailCode
    case stockQuote
    case stockKlines
    case intradayKlines
    case stockIndices
    case indexDaily
    case stockSearch
    case stockBasics
    case dailyBasic
    case stockLimit
    case sectorMoneyflow
    case sectorMoneyflowTrend
    case stockMoneyflow
    case moneyflowHsgt
    case topList
    case topInst
    case thsIndex
    case thsDaily
    case thsMember
    case watchlist
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
        case .weatherBeijing: return "北京天气"
        }
    }

    var method: String {
        switch self {
        case .testLogin, .sendEmailCode, .verifyEmailCode:
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
        case .healthRoot, .healthCheck, .stockIndices, .watchlist, .weatherBeijing, .stockBasics:
            params = []
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
            var components = URLComponents(string: baseURL + "/stocks/klines/\(paramValue("code"))")!
            var queryItems: [URLQueryItem] = []
            let period = paramValue("period")
            if !period.isEmpty { queryItems.append(URLQueryItem(name: "period", value: period)) }
            let limit = paramValue("limit")
            if !limit.isEmpty { queryItems.append(URLQueryItem(name: "limit", value: limit)) }
            if !queryItems.isEmpty { components.queryItems = queryItems }
            urlString = components.url?.absoluteString ?? ""
        case .intradayKlines:
            var components = URLComponents(string: baseURL + "/stocks/intraday/\(paramValue("code"))")!
            var queryItems: [URLQueryItem] = []
            let period = paramValue("period")
            if !period.isEmpty { queryItems.append(URLQueryItem(name: "period", value: period)) }
            let limit = paramValue("limit")
            if !limit.isEmpty { queryItems.append(URLQueryItem(name: "limit", value: limit)) }
            if !queryItems.isEmpty { components.queryItems = queryItems }
            urlString = components.url?.absoluteString ?? ""
        case .stockIndices:
            urlString = baseURL + "/stocks/indices"
        case .indexDaily:
            var components = URLComponents(string: baseURL + "/stocks/index-daily/\(paramValue("code"))")!
            let limit = paramValue("limit")
            if !limit.isEmpty { components.queryItems = [URLQueryItem(name: "limit", value: limit)] }
            urlString = components.url?.absoluteString ?? ""
        case .stockSearch:
            var components = URLComponents(string: baseURL + "/stocks/search")!
            var queryItems: [URLQueryItem] = []
            let q = paramValue("q")
            if !q.isEmpty { queryItems.append(URLQueryItem(name: "q", value: q)) }
            let limit = paramValue("limit")
            if !limit.isEmpty { queryItems.append(URLQueryItem(name: "limit", value: limit)) }
            if !queryItems.isEmpty { components.queryItems = queryItems }
            urlString = components.url?.absoluteString ?? ""
        case .stockBasics:
            urlString = baseURL + "/stocks/basics"
        case .dailyBasic:
            var components = URLComponents(string: baseURL + "/stocks/daily-basic/\(paramValue("code"))")!
            let limit = paramValue("limit")
            if !limit.isEmpty { components.queryItems = [URLQueryItem(name: "limit", value: limit)] }
            urlString = components.url?.absoluteString ?? ""
        case .stockLimit:
            var components = URLComponents(string: baseURL + "/stocks/stock-limit")!
            var queryItems: [URLQueryItem] = []
            let tradeDate = paramValue("trade_date")
            if !tradeDate.isEmpty { queryItems.append(URLQueryItem(name: "trade_date", value: tradeDate)) }
            let limit = paramValue("limit")
            if !limit.isEmpty { queryItems.append(URLQueryItem(name: "limit", value: limit)) }
            if !queryItems.isEmpty { components.queryItems = queryItems }
            urlString = components.url?.absoluteString ?? ""
        case .sectorMoneyflow:
            var components = URLComponents(string: baseURL + "/stocks/sector-moneyflow")!
            var queryItems: [URLQueryItem] = []
            let sectorType = paramValue("sector_type")
            if !sectorType.isEmpty { queryItems.append(URLQueryItem(name: "sector_type", value: sectorType)) }
            let tradeDate = paramValue("trade_date")
            if !tradeDate.isEmpty { queryItems.append(URLQueryItem(name: "trade_date", value: tradeDate)) }
            let sortBy = paramValue("sort_by")
            if !sortBy.isEmpty { queryItems.append(URLQueryItem(name: "sort_by", value: sortBy)) }
            let limit = paramValue("limit")
            if !limit.isEmpty { queryItems.append(URLQueryItem(name: "limit", value: limit)) }
            if !queryItems.isEmpty { components.queryItems = queryItems }
            urlString = components.url?.absoluteString ?? ""
        case .sectorMoneyflowTrend:
            var components = URLComponents(string: baseURL + "/stocks/sector-moneyflow/trend")!
            var queryItems: [URLQueryItem] = []
            let sectorType = paramValue("sector_type")
            if !sectorType.isEmpty { queryItems.append(URLQueryItem(name: "sector_type", value: sectorType)) }
            let startDate = paramValue("start_date")
            if !startDate.isEmpty { queryItems.append(URLQueryItem(name: "start_date", value: startDate)) }
            let endDate = paramValue("end_date")
            if !endDate.isEmpty { queryItems.append(URLQueryItem(name: "end_date", value: endDate)) }
            let topN = paramValue("top_n")
            if !topN.isEmpty { queryItems.append(URLQueryItem(name: "top_n", value: topN)) }
            if !queryItems.isEmpty { components.queryItems = queryItems }
            urlString = components.url?.absoluteString ?? ""
        case .stockMoneyflow:
            var components = URLComponents(string: baseURL + "/stocks/moneyflow/\(paramValue("code"))")!
            let limit = paramValue("limit")
            if !limit.isEmpty { components.queryItems = [URLQueryItem(name: "limit", value: limit)] }
            urlString = components.url?.absoluteString ?? ""
        case .moneyflowHsgt:
            var components = URLComponents(string: baseURL + "/stocks/moneyflow-hsgt")!
            var queryItems: [URLQueryItem] = []
            let startDate = paramValue("start_date")
            if !startDate.isEmpty { queryItems.append(URLQueryItem(name: "start_date", value: startDate)) }
            let endDate = paramValue("end_date")
            if !endDate.isEmpty { queryItems.append(URLQueryItem(name: "end_date", value: endDate)) }
            let limit = paramValue("limit")
            if !limit.isEmpty { queryItems.append(URLQueryItem(name: "limit", value: limit)) }
            if !queryItems.isEmpty { components.queryItems = queryItems }
            urlString = components.url?.absoluteString ?? ""
        case .topList:
            var components = URLComponents(string: baseURL + "/stocks/top-list")!
            var queryItems: [URLQueryItem] = []
            let tradeDate = paramValue("trade_date")
            if !tradeDate.isEmpty { queryItems.append(URLQueryItem(name: "trade_date", value: tradeDate)) }
            let limit = paramValue("limit")
            if !limit.isEmpty { queryItems.append(URLQueryItem(name: "limit", value: limit)) }
            if !queryItems.isEmpty { components.queryItems = queryItems }
            urlString = components.url?.absoluteString ?? ""
        case .topInst:
            var components = URLComponents(string: baseURL + "/stocks/top-inst")!
            var queryItems: [URLQueryItem] = []
            let tradeDate = paramValue("trade_date")
            if !tradeDate.isEmpty { queryItems.append(URLQueryItem(name: "trade_date", value: tradeDate)) }
            let code = paramValue("code")
            if !code.isEmpty { queryItems.append(URLQueryItem(name: "code", value: code)) }
            let limit = paramValue("limit")
            if !limit.isEmpty { queryItems.append(URLQueryItem(name: "limit", value: limit)) }
            if !queryItems.isEmpty { components.queryItems = queryItems }
            urlString = components.url?.absoluteString ?? ""
        case .thsIndex:
            var components = URLComponents(string: baseURL + "/stocks/ths-index")!
            let limit = paramValue("limit")
            if !limit.isEmpty { components.queryItems = [URLQueryItem(name: "limit", value: limit)] }
            urlString = components.url?.absoluteString ?? ""
        case .thsDaily:
            var components = URLComponents(string: baseURL + "/stocks/ths-daily/\(paramValue("code"))")!
            let limit = paramValue("limit")
            if !limit.isEmpty { components.queryItems = [URLQueryItem(name: "limit", value: limit)] }
            urlString = components.url?.absoluteString ?? ""
        case .thsMember:
            var components = URLComponents(string: baseURL + "/stocks/ths-member/\(paramValue("code"))")!
            let limit = paramValue("limit")
            if !limit.isEmpty { components.queryItems = [URLQueryItem(name: "limit", value: limit)] }
            urlString = components.url?.absoluteString ?? ""
        case .watchlist:
            urlString = baseURL + "/stocks/watchlist"
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

    private func paramValue(_ key: String) -> String {
        params.first(where: { $0.key == key })?.value.trimmingCharacters(in: .whitespaces) ?? ""
    }

    private func updateRequestURL() {
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
