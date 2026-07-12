import SwiftUI

struct StockDetailView: View {
    let code: String
    let name: String

    @State private var selectedPeriod: KlinePeriod = .trend
    @State private var klines: [KlineData] = []
    @State private var dailyKlines: [KlineData] = []
    @State private var intradayData: [IntradayKlineData] = []
    @State private var selectedKline: KlineData?
    @State private var quote: StockData?
    @State private var dailyBasic: DailyBasicData?
    @State private var moneyflow: MoneyFlowData?
    @State private var concepts: [StockConcept] = []
    @State private var companyInfo: StockCompanyInfo?
    @State private var finaIndicator: FinaIndicator?
    @State private var topListItem: TopListItem?
    @State private var topInstItems: [TopInstItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var refreshTimer: Timer?
    @State private var watchlistUpdateFlag = 0
    @State private var portfolioUpdateFlag = 0
    @State private var isInPortfolio = false
    @State private var currentPortfolioItem: PortfolioItem?
    @State private var showingPortfolioSheet = false
    @State private var selectedDetailTab: DetailTab = .indicators

    // MARK: - V1.0 规划模块
    // 1. ✅ AI 总结（待接入）
    // 2. ✅ K线/分时
    // 3. ✅ 主力资金
    // 4. ✅ 大小单/内外盘
    // 5. ✅ 所属板块/概念
    // 6. 🔲 新闻
    // 7. 🔲 公告
    // 8. ✅ 财务（指标）
    // 9. ✅ 龙虎榜

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    headerView
                    klineSection
                    stockInfoSection
                    detailContentSection
                    // TODO: 新闻 section
                    // TODO: 公告 section
                }
            }
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
        .onChange(of: selectedPeriod) { _, _ in
            selectedKline = nil
            Task {
                await loadKlines()
            }
            setupAutoRefresh()
        }
        .onAppear {
            setupAutoRefresh()
        }
        .onDisappear {
            stopAutoRefresh()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                if let price = displayPrice {
                    Text(String(format: "%.2f", price))
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(displayColor)
                } else {
                    skeletonBar(width: 100, height: 34)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        if let changePercent = selectedKlineChangePercent {
                            Text(String(format: "%.2f%%", changePercent))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(displayColor)
                        }

                        if let change = selectedKlineChange {
                            Text(String(format: "%.2f", change))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(displayColor)
                        }
                    }

                    HStack(spacing: 6) {
                        Text(code)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        if let selectedKline = selectedKline {
                            Text(formatHeaderDate(selectedKline.tradeDate))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } else if let latest = latestTradeDateString {
                            Text(formatHeaderDate(latest))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                if isInPortfolio {
                    Menu {
                        Button {
                            showingPortfolioSheet = true
                        } label: {
                            Label("编辑持仓", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            Task { await removeFromPortfolio() }
                        } label: {
                            Label("删除持仓", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "briefcase.fill")
                            .font(.title3)
                            .foregroundStyle(YPColor.accent)
                    }
                    .sheet(isPresented: $showingPortfolioSheet) {
                        PortfolioEditSheet(
                            code: code,
                            name: name,
                            existingItem: currentPortfolioItem,
                            onSave: {
                                Task {
                                    await loadPortfolioStatus()
                                    portfolioUpdateFlag += 1
                                }
                            }
                        )
                    }
                } else {
                    Button {
                        showingPortfolioSheet = true
                    } label: {
                        Image(systemName: "briefcase")
                            .font(.title3)
                            .foregroundStyle(Color.gray)
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showingPortfolioSheet) {
                        PortfolioEditSheet(
                            code: code,
                            name: name,
                            existingItem: nil,
                            onSave: {
                                Task {
                                    await loadPortfolioStatus()
                                    portfolioUpdateFlag += 1
                                }
                            }
                        )
                    }
                }

                Button {
                    toggleWatchlist()
                } label: {
                    Image(systemName: isInWatchlist ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle(isInWatchlist ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
            }

            headerStatsGrid
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }

    private var latestTradeDateString: String? {
        if selectedPeriod.usesIntradayData, let last = intradayData.max(by: { $0.datetime < $1.datetime }) {
            return last.datetime
        }
        if let last = klines.max(by: { $0.tradeDate < $1.tradeDate }) {
            return last.tradeDate
        }
        return quote?.updatedAt
    }

    private var headerStatsGrid: some View {
        let stats = headerStats
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
            statItem("今开", value: stats.open)
            statItem("最高", value: stats.high)
            statItem("最低", value: stats.low)
            statItem("昨收", value: stats.preClose)
            statItem("成交量", value: stats.volume, isVolume: true)
            statItem("成交额", value: stats.amount, isVolume: true)
            statItem("换手", value: stats.turnoverRate, suffix: "%")
            statItem("量比", value: stats.volumeRatio)
        }
    }

    private struct HeaderStats {
        var open: Double?
        var high: Double?
        var low: Double?
        var preClose: Double?
        var volume: Double?
        var amount: Double?
        var turnoverRate: Double?
        var volumeRatio: Double?
    }

    private var headerStats: HeaderStats {
        var stats = HeaderStats()

        // 优先用最新日K数据填充开高低量额
        let latestDaily = dailyKlines.first

        stats.open = latestDaily?.open
        stats.high = latestDaily?.high
        stats.low = latestDaily?.low
        stats.volume = latestDaily?.volume
        stats.amount = latestDaily?.amount
        stats.preClose = quote?.preClose
        stats.turnoverRate = dailyBasic?.turnoverRate
        stats.volumeRatio = dailyBasic?.volumeRatio

        return stats
    }

    private func statItem(_ title: String, value: Double?, isVolume: Bool = false, suffix: String? = nil) -> some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let value = value {
                Text(isVolume ? formatBigNumber(value) : formatIndicator(value, suffix: suffix))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                Text("--")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func formatHeaderDate(_ dateString: String) -> String {
        if dateString.count == 8 {
            let year = dateString.prefix(4)
            let month = dateString.dropFirst(4).prefix(2)
            let day = dateString.suffix(2)
            return "\(year)-\(month)-\(day)"
        }
        // 分时格式：YYYYMMDD HH:MM:SS
        let parts = dateString.split(separator: " ")
        if parts.count == 2, parts[0].count == 8 {
            let date = parts[0]
            let time = parts[1]
            return "\(date.prefix(4))-\(date.dropFirst(4).prefix(2))-\(date.suffix(2)) \(time.prefix(5))"
        }
        return dateString
    }

    private var isInWatchlist: Bool {
        // 依赖 flag 强制 SwiftUI 在点击后重新评估
        _ = watchlistUpdateFlag
        return WatchlistService.contains(code: code)
    }

    private func toggleWatchlist() {
        if isInWatchlist {
            WatchlistService.remove(code: code)
            watchlistUpdateFlag += 1
        } else {
            let added = WatchlistService.add(code: code, name: name)
            if added {
                watchlistUpdateFlag += 1
            } else {
                errorMessage = "自选股最多 20 只，建议精简票池后再添加"
            }
        }
    }

    private func loadPortfolioStatus() async {
        do {
            let portfolio = try await StockService.fetchPortfolio()
            currentPortfolioItem = portfolio.first { $0.code == code }
            isInPortfolio = currentPortfolioItem != nil
        } catch {
            if error is CancellationError { return }
            print("[StockDetail] 加载持仓状态失败: \(error.localizedDescription)")
        }
    }

    private func removeFromPortfolio() async {
        do {
            try await StockService.removeFromPortfolio(code: code)
            await loadPortfolioStatus()
            portfolioUpdateFlag += 1
        } catch {
            print("[StockDetail] 删除持仓失败: \(error.localizedDescription)")
        }
    }

    private func togglePortfolio() {
        showingPortfolioSheet = true
    }

    private var selectedKlineChangePercent: Double? {
        if let selectedKline = selectedKline {
            if let preClose = quote?.preClose, preClose != 0 {
                return (selectedKline.close - preClose) / preClose * 100
            }
            guard selectedKline.open != 0 else { return 0 }
            return (selectedKline.close - selectedKline.open) / selectedKline.open * 100
        }

        if selectedPeriod.usesIntradayData, let preClose = quote?.preClose, preClose != 0,
           let latestClose = latestIntradayClose {
            return (latestClose - preClose) / preClose * 100
        }

        return quote?.changePercent
    }

    private var selectedKlineChange: Double? {
        guard let percent = selectedKlineChangePercent else { return nil }
        if let selectedKline = selectedKline {
            return selectedKline.close * percent / 100
        }
        if selectedPeriod.usesIntradayData, let latestClose = latestIntradayClose {
            return latestClose * percent / 100
        }
        if let price = quote?.price {
            return price * percent / 100
        }
        return nil
    }

    private var displayPrice: Double? {
        if let selectedKline = selectedKline {
            return selectedKline.close
        }
        if selectedPeriod.usesIntradayData, let latestClose = latestIntradayClose {
            return latestClose
        }
        return quote?.price
    }

    private var latestIntradayClose: Double? {
        intradayData.max(by: { $0.datetime < $1.datetime })?.close
    }

    private var displayColor: Color {
        let change = selectedKlineChangePercent ?? 0
        return change >= 0 ? .red : .green
    }

    // MARK: - Detail Tabs

    private enum DetailTab: String, CaseIterable {
        case indicators = "指标"
        case company = "公司"
        case moneyflow = "资金"
        case concepts = "概念"
        case topList = "龙虎榜"
    }

    private var detailTabsPicker: some View {
        HStack(spacing: 4) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedDetailTab = tab
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 12, weight: selectedDetailTab == tab ? .semibold : .regular))
                        .foregroundStyle(selectedDetailTab == tab ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(selectedDetailTab == tab ? Color(red: 0.25, green: 0.25, blue: 0.28) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - 公司信息

    private var companyInfoContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("公司信息")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            if let company = companyInfo {
                VStack(alignment: .leading, spacing: 10) {
                    if let introduction = company.introduction, !introduction.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("公司简介")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(introduction)
                                .font(.subheadline)
                                .lineSpacing(4)
                        }
                    }

                    if let mainBusiness = company.mainBusiness, !mainBusiness.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("主营业务")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(mainBusiness)
                                .font(.subheadline)
                                .lineSpacing(4)
                        }
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        companyInfoItem(title: "注册地", value: company.province ?? company.city)
                        companyInfoItem(title: "员工人数", value: company.employees.map { "\($0)人" })
                        companyInfoItem(title: "成立日期", value: company.setupDate)
                        companyInfoItem(title: "董事长", value: company.chairman)
                        companyInfoItem(title: "总经理", value: company.manager)
                        companyInfoItem(title: "官网", value: company.website)
                    }
                }
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Spacer()
                }
                .padding(.vertical, 20)
            }
        }
    }

    private func companyInfoItem(title: String, value: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value ?? "--")
                .font(.subheadline)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var detailContentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            detailTabsPicker

            Group {
                switch selectedDetailTab {
                case .indicators:
                    indicatorsContent
                case .company:
                    companyInfoContent
                case .moneyflow:
                    moneyflowContent
                case .concepts:
                    conceptsContent
                case .topList:
                    VStack(alignment: .leading, spacing: 12) {
                        topListContent
                        Divider()
                        topInstContent
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        HStack(spacing: 4) {
            ForEach(KlinePeriod.allCases, id: \.self) { period in
                Button(action: {
                    selectedPeriod = period
                }) {
                    Text(period.title)
                        .font(.system(size: 12, weight: selectedPeriod == period ? .semibold : .regular))
                        .foregroundStyle(selectedPeriod == period ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(selectedPeriod == period ? Color(red: 0.25, green: 0.25, blue: 0.28) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - K 线 / 分时 Section

    private var klineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            periodPicker

            VStack(alignment: .leading, spacing: 8) {
                switch selectedPeriod {
                case .trend:
                    if intradayData.isEmpty {
                        ProgressView()
                            .scaleEffect(1.2)
                            .frame(maxWidth: .infinity, minHeight: 360)
                    } else {
                        IntradayLineChartView(data: intradayData, preClose: quote?.preClose)
                            .frame(height: 360)
                    }
                case .intraday, .day, .week, .month, .year:
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, minHeight: 360)
                    } else if isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                            .frame(maxWidth: .infinity, minHeight: 360)
                    } else {
                        KLineChartView(data: klines, selectedKline: $selectedKline)
                            .frame(height: 360)
                    }
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    // MARK: - 股票基础信息

    private var stockInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(code)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let price = displayPrice {
                        Text(String(format: "%.2f", price))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(displayColor)
                    } else {
                        Text("--")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 6) {
                        if let changePercent = selectedKlineChangePercent {
                            Text(String(format: "%+.2f%%", changePercent))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(displayColor)
                        }
                        if let change = selectedKlineChange {
                            Text(String(format: "%+.2f", change))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(displayColor)
                        }
                    }
                }
            }

            if let dailyBasic = dailyBasic {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    indicatorItem("总市值", value: dailyBasic.totalMv, suffix: nil, isVolume: true)
                    indicatorItem("流通市值", value: dailyBasic.circMv, suffix: nil, isVolume: true)
                    indicatorItem("市盈率 PE", value: dailyBasic.pe, suffix: nil)
                    indicatorItem("PE TTM", value: dailyBasic.peTtm, suffix: nil)
                    indicatorItem("市净率 PB", value: dailyBasic.pb, suffix: nil)
                    indicatorItem("换手率", value: dailyBasic.turnoverRate, suffix: "%")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 12)
        .padding(.top, 12)
    }

    // MARK: - Indicators Content

    private var indicatorsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("估值指标")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            if let dailyBasic = dailyBasic {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    indicatorItem("市盈率 PE", value: dailyBasic.pe, suffix: nil)
                    indicatorItem("PE TTM", value: dailyBasic.peTtm, suffix: nil)
                    indicatorItem("市净率 PB", value: dailyBasic.pb, suffix: nil)
                    indicatorItem("市销率 PS", value: dailyBasic.ps, suffix: nil)
                    indicatorItem("PS TTM", value: dailyBasic.psTtm, suffix: nil)
                    indicatorItem("换手率", value: dailyBasic.turnoverRate, suffix: "%")
                    indicatorItem("换手(自由)", value: dailyBasic.turnoverRateF, suffix: "%")
                    indicatorItem("量比", value: dailyBasic.volumeRatio, suffix: nil)
                    indicatorItem("总市值", value: dailyBasic.totalMv, suffix: nil, isVolume: true)
                    indicatorItem("流通市值", value: dailyBasic.circMv, suffix: nil, isVolume: true)
                    indicatorItem("自由流通市值", value: dailyBasic.freeShare.map { $0 * (dailyBasic.close ?? 0) }, suffix: nil, isVolume: true)
                    indicatorItem("股息率 TTM", value: dailyBasic.dvTtm, suffix: "%")
                }
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Spacer()
                }
                .padding(.vertical, 20)
            }

            Text("财务指标")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            if let fina = finaIndicator {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    indicatorItem("ROE", value: fina.roe, suffix: "%")
                    indicatorItem("EPS", value: fina.eps, suffix: "元")
                    indicatorItem("毛利率", value: fina.grossprofitMargin, suffix: "%")
                    indicatorItem("净利率", value: fina.netprofitMargin, suffix: "%")
                    indicatorItem("每股净资产", value: fina.bps, suffix: "元")
                }
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Spacer()
                }
                .padding(.vertical, 20)
            }
        }
    }

    // MARK: - 资金流向 Content

    private var moneyflowContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("资金流向")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            if let mf = moneyflow {
                VStack(spacing: 10) {
                    HStack {
                        Text("主力净流入")
                            .font(.callout)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(mf.mainForceNetFormatted)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(mf.mainForceNet >= 0 ? .red : .green)
                    }

                    Divider()

                    moneyflowRow("小单", buy: mf.buySmAmount, sell: mf.sellSmAmount)
                    moneyflowRow("中单", buy: mf.buyMdAmount, sell: mf.sellMdAmount)
                    moneyflowRow("大单", buy: mf.buyLgAmount, sell: mf.sellLgAmount)
                    moneyflowRow("特大单", buy: mf.buyElgAmount, sell: mf.sellElgAmount)
                }
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Spacer()
                }
                .padding(.vertical, 20)
            }
        }
    }

    private func moneyflowRow(_ label: String, buy: Double?, sell: Double?) -> some View {
        let net = (buy ?? 0) - (sell ?? 0)
        return VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 44, alignment: .leading)

                Spacer()

                Text("买 \(formatMoneyflow(buy ?? 0))")
                    .font(.system(size: 11))
                    .foregroundStyle(.red)

                Text("卖 \(formatMoneyflow(sell ?? 0))")
                    .font(.system(size: 11))
                    .foregroundStyle(.green)

                Text(formatMoneyflow(net))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(net >= 0 ? .red : .green)
                    .frame(width: 60, alignment: .trailing)
            }

            GeometryReader { geometry in
                let total = (buy ?? 0) + (sell ?? 0)
                let buyRatio = total > 0 ? CGFloat((buy ?? 0) / total) : 0.5
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.red.opacity(0.7))
                        .frame(width: max(0, geometry.size.width * buyRatio - 1))
                    Rectangle()
                        .fill(Color.green.opacity(0.7))
                        .frame(width: max(0, geometry.size.width * (1 - buyRatio) - 1))
                }
            }
            .frame(height: 5)
            .clipShape(Capsule())
        }
    }

    private func formatMoneyflow(_ value: Double) -> String {
        if abs(value) >= 10000 {
            return String(format: "%.2f亿", value / 10000.0)
        }
        return String(format: "%.0f万", value)
    }

    // MARK: - 所属概念 Section

    private var conceptsContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("所属概念")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            if concepts.isEmpty {
                Text("暂无概念数据")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(concepts) { concept in
                        NavigationLink {
                            SectorDetailView(
                                sector: SectorMoneyflowData(
                                    tsCode: concept.conceptId,
                                    tradeDate: "",
                                    name: concept.conceptName,
                                    leadStock: nil,
                                    closePrice: nil,
                                    pctChange: nil,
                                    companyNum: nil,
                                    pctChangeStock: nil,
                                    netBuyAmount: nil,
                                    netSellAmount: nil,
                                    netAmount: nil
                                ),
                                isConcept: true
                            )
                        } label: {
                            Text(concept.conceptName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - 龙虎榜 Content

    private var topListContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("龙虎榜")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            if let item = topListItem {
                VStack(spacing: 8) {
                    HStack {
                        Text("上榜日期")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatHeaderDate(item.tradeDate))
                            .font(.system(size: 12, weight: .medium))
                    }

                    HStack {
                        Text("收盘价")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.2f", item.close ?? 0))
                            .font(.system(size: 12, weight: .medium))
                    }

                    HStack {
                        Text("涨跌幅")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.2f%%", item.pctChange ?? 0))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle((item.pctChange ?? 0) >= 0 ? .red : .green)
                    }

                    HStack {
                        Text("成交额")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatBigNumber(item.amount ?? 0))
                            .font(.system(size: 12, weight: .medium))
                    }

                    HStack {
                        Text("净买入")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatBigNumber(item.netAmount ?? 0))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle((item.netAmount ?? 0) >= 0 ? .red : .green)
                    }

                    if let reason = item.reason, !reason.isEmpty {
                        HStack(alignment: .top) {
                            Text("上榜原因")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(reason)
                                .font(.system(size: 11))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                }
            } else {
                Text("近期无龙虎榜数据")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - 龙虎榜机构明细 Content

    private var topInstContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("龙虎榜机构明细")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            if topInstItems.isEmpty {
                Text("近期无机构明细数据")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 0) {
                    ForEach(topInstItems.prefix(10)) { item in
                        topInstRow(item)
                        if item.id != topInstItems.prefix(10).last?.id {
                            Divider()
                                .padding(.leading)
                        }
                    }
                }

                if topInstItems.count > 10 {
                    Text("还有 \(topInstItems.count - 10) 条机构明细")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
            }
        }
    }

    private func topInstRow(_ item: TopInstItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.exalter ?? "未知机构")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                Text(item.tradeDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("买入: \(formatBigNumber(item.buy ?? 0))")
                    .font(.system(size: 11))
                    .foregroundStyle(.red)

                Spacer()

                Text("卖出: \(formatBigNumber(item.sell ?? 0))")
                    .font(.system(size: 11))
                    .foregroundStyle(.green)

                Spacer()

                Text("净买: \(formatBigNumber(item.netBuy ?? 0))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle((item.netBuy ?? 0) >= 0 ? .red : .green)
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Indicator Helpers

    private func indicatorItem(_ title: String, value: Double?, suffix: String?, isVolume: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let value = value {
                Text(isVolume ? formatBigNumber(value) : formatIndicator(value, suffix: suffix))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                Text("-")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private func formatIndicator(_ value: Double, suffix: String?) -> String {
        if let suffix = suffix {
            return String(format: "%.2f%@", value, suffix)
        }
        return String(format: "%.2f", value)
    }

    private func formatBigNumber(_ value: Double) -> String {
        if value >= 100_000_000 {
            return String(format: "%.2f亿", value / 100_000_000)
        } else if value >= 10_000 {
            return String(format: "%.2f万", value / 10_000)
        } else {
            return String(format: "%.2f", value)
        }
    }

    // MARK: - Skeleton Helpers

    private func skeletonBar(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.25))
            .frame(width: width, height: height)
            .shimmer()
    }

    // MARK: - Auto Refresh (分时模式每分钟刷新)

    private func setupAutoRefresh() {
        stopAutoRefresh()

        // 盘后/非交易日不再定时刷新
        guard MarketCalendar.isTradingTime() else { return }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                guard MarketCalendar.isTradingTime() else {
                    stopAutoRefresh()
                    return
                }
                await loadQuote()
                await loadIntraday()
                if selectedPeriod == .intraday {
                    await loadKlines()
                }
            }
        }
    }

    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Data Loading

    private func loadData() async {
        async let quoteTask: () = loadQuote()
        async let intradayTask: () = loadIntraday()
        async let klinesTask: () = loadKlines()
        async let dailyKlinesTask: () = loadDailyKlines()
        async let indicatorsTask: () = loadIndicators()
        async let moneyflowTask: () = loadMoneyflow()
        async let conceptsTask: () = loadConcepts()
        async let companyTask: () = loadCompanyInfo()
        async let finaTask: () = loadFinaIndicator()
        async let topListTask: () = loadTopList()
        async let topInstTask: () = loadTopInst()
        async let portfolioTask: () = loadPortfolioStatus()
        _ = await (quoteTask, intradayTask, klinesTask, dailyKlinesTask, indicatorsTask, moneyflowTask, conceptsTask, companyTask, finaTask, topListTask, topInstTask, portfolioTask)
    }

    private func loadQuote(policy: CachePolicy = .default) async {
        do {
            quote = try await StockService.fetchQuote(code: code, policy: policy)
        } catch {
            print("加载行情失败: \(error.localizedDescription)")
        }
    }

    private func loadIntraday(policy: CachePolicy = .default) async {
        do {
            intradayData = try await StockService.fetchIntradayKlines(code: code, period: "1", limit: 240, policy: policy)
        } catch {
            print("加载分时数据失败: \(error.localizedDescription)")
        }
    }

    private func loadKlines() async {
        errorMessage = nil

        // 走势折线图用 intradayData，不操作 klines
        if selectedPeriod == .trend {
            if intradayData.isEmpty {
                await loadIntraday()
            }
            return
        }

        // 分时 K 线不缓存，直接从服务端拉取
        if selectedPeriod == .intraday {
            // 首次加载才显示 loading，自动刷新时保持现有数据展示
            if klines.isEmpty {
                isLoading = true
            }
            defer { isLoading = false }

            do {
                let intradayData = try await StockService.fetchIntradayKlines(code: code, period: "1", limit: 240)
                klines = intradayData.map { $0.toKlineData() }
            } catch APIError.unauthorized {
                errorMessage = "未登录，请先登录"
            } catch {
                if klines.isEmpty {
                    errorMessage = "加载失败: \(error.localizedDescription)"
                }
            }
            return
        }

        // 日/周/月/年 K 线走缓存逻辑
        // 1. 先读本地缓存并展示
        let cached = KLineCacheService.load(code: code, period: selectedPeriod)
        if !cached.isEmpty {
            klines = cached
            // 有缓存时不必显示骨架屏，直接展示旧数据
            isLoading = false
        } else {
            isLoading = true
        }

        defer { isLoading = false }

        do {
            let limit = remoteFetchLimit(for: selectedPeriod, cachedCount: cached.count)
            let remote = try await StockService.fetchKlines(
                code: code,
                period: selectedPeriod,
                limit: limit
            )

            let merged = KLineCacheService.merge(local: cached, remote: remote)
            klines = merged
            KLineCacheService.save(code: code, period: selectedPeriod, data: merged)
        } catch APIError.unauthorized {
            errorMessage = "未登录，请先登录"
        } catch {
            // 有缓存时不因网络失败而提示，静默保留旧数据
            if cached.isEmpty {
                errorMessage = "加载失败: \(error.localizedDescription)"
            }
        }
    }

    /// 远程请求条数：
    /// - 本地无缓存时拉全量（日线近两年，其他周期适量）
    /// - 本地有缓存时只拉最近一段，用于增量更新
    private func remoteFetchLimit(for period: KlinePeriod, cachedCount: Int) -> Int {
        if cachedCount > 0 {
            switch period {
            case .trend, .intraday: return 240
            case .day: return 60
            case .week: return 20
            case .month: return 12
            case .year: return 5
            }
        } else {
            switch period {
            case .trend, .intraday: return 240
            case .day: return 500
            case .week: return 200
            case .month: return 120
            case .year: return 30
            }
        }
    }

    private func loadDailyKlines(policy: CachePolicy = .default) async {
        do {
            dailyKlines = try await StockService.fetchKlines(code: code, period: .day, limit: 2)
        } catch {
            print("加载日K数据失败: \(error.localizedDescription)")
        }
    }

    private func loadIndicators(policy: CachePolicy = .default) async {
        do {
            let data = try await StockService.fetchDailyBasic(code: code, limit: 1, policy: policy)
            dailyBasic = data.first
        } catch {
            print("加载指标失败: \(error.localizedDescription)")
        }
    }

    private func loadMoneyflow(policy: CachePolicy = .default) async {
        do {
            let data = try await MarketService.fetchMoneyFlow(code: code, limit: 5, policy: policy)
            moneyflow = data.first
        } catch {
            print("加载资金流向失败: \(error.localizedDescription)")
        }
    }

    private func loadConcepts(policy: CachePolicy = .default) async {
        do {
            concepts = try await StockService.fetchConcepts(code: code, policy: policy)
        } catch {
            print("加载概念失败: \(error.localizedDescription)")
        }
    }

    private func loadCompanyInfo() async {
        do {
            companyInfo = try await StockService.fetchStockCompany(code: code)
        } catch {
            print("加载公司信息失败: \(error.localizedDescription)")
        }
    }

    private func loadFinaIndicator() async {
        do {
            finaIndicator = try await StockService.fetchFinaIndicator(code: code, limit: 1)
        } catch {
            print("加载财务指标失败: \(error.localizedDescription)")
        }
    }

    private func loadTopList(policy: CachePolicy = .default) async {
        do {
            let items = try await MarketService.fetchTopList(limit: 100, policy: policy)
            topListItem = items.first { $0.tsCode.contains(code) || code.contains($0.tsCode) }
        } catch {
            print("加载龙虎榜失败: \(error.localizedDescription)")
        }
    }

    private func loadTopInst(policy: CachePolicy = .default) async {
        do {
            topInstItems = try await MarketService.fetchTopInst(code: code, limit: 100, policy: policy)
        } catch {
            print("加载龙虎榜机构失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Shimmer Effect

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.15),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

private extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

#Preview {
    NavigationStack {
        StockDetailView(code: "000001", name: "平安银行")
    }
}
