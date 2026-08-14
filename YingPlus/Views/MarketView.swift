import SwiftUI

// MARK: - 资金流向子标签

enum FundFlowTab: String, CaseIterable, Identifiable {
    case north = "北向"
    case industry = "行业"
    case concept = "概念"

    var id: String { rawValue }
}

// MARK: - 市场页

struct MarketView: View {
    @State private var searchCode = ""
    @State private var allStocks: [StockBasicInfo] = []
    @State private var filteredStocks: [StockBasicInfo] = []
    @State private var isLoadingStocks = false
    @State private var selectedStock: StockBasicInfo?
    @State private var watchlistCodes: Set<String> = []
    @State private var portfolioCodes: Set<String> = []
    @State private var portfolioItems: [PortfolioItem] = []
    @State private var selectedPortfolioStock: StockBasicInfo?
    @State private var selectedFundFlowTab: FundFlowTab = .north
    @State private var hotSectors: [SectorMoneyflowData] = []
    @State private var industryFlow: [SectorMoneyflowData] = []
    @State private var conceptFlow: [SectorMoneyflowData] = []
    @State private var hsgtFlow: [HsgtFlowData] = []
    @State private var isLoadingData = false
    @State private var limitErrorMessage: String?
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    searchSection
                    aShareContent
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("市场")
            .refreshable {
                await loadStockBasics()
                await loadMarketData(forceRefresh: true)
                watchlistCodes = Set(WatchlistService.load().map(\.code))
                await loadPortfolioCodes()
            }
            .task {
                await loadStockBasics()
                await loadMarketData()
                watchlistCodes = Set(WatchlistService.load().map(\.code))
                await loadPortfolioCodes()
            }
            .sheet(item: $selectedPortfolioStock) { stock in
                PortfolioEditSheet(
                    code: stock.code,
                    name: stock.name,
                    existingItem: portfolioItem(for: stock),
                    onSave: {
                        Task { await loadPortfolioCodes() }
                    }
                )
            }
        }
    }

    // MARK: - 搜索

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let limitErrorMessage {
                Text(limitErrorMessage)
                    .font(.caption)
                    .foregroundStyle(YPColor.up)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(YPColor.up.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    TextField("搜索股票代码或名称", text: $searchCode)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.search)
                        .focused($isSearchFieldFocused)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                if isLoadingStocks {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 36, height: 36)
                }
            }

            if !searchCode.isEmpty {
                let suggestions = filteredStocks
                if !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(suggestions.prefix(10)) { stock in
                            HStack(spacing: 0) {
                                Button {
                                    isSearchFieldFocused = false
                                    selectedStock = stock
                                    searchCode = ""
                                    filteredStocks = []
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(stock.code)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.primary)
                                        Text(stock.name)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                Button {
                                    toggleWatchlist(stock: stock)
                                } label: {
                                    Image(systemName: watchlistCodes.contains(stock.code) ? "star.fill" : "star")
                                        .font(.subheadline)
                                        .foregroundStyle(watchlistCodes.contains(stock.code) ? YPColor.warning : Color.gray)
                                        .frame(width: 36, height: 44)
                                }
                                .buttonStyle(.plain)

                                if portfolioCodes.contains(stock.code) {
                                    Menu {
                                        Button {
                                            selectedPortfolioStock = stock
                                        } label: {
                                            Label("编辑持仓", systemImage: "pencil")
                                        }
                                        Button(role: .destructive) {
                                            Task { await removeFromPortfolio(stock: stock) }
                                        } label: {
                                            Label("删除持仓", systemImage: "trash")
                                        }
                                    } label: {
                                        Image(systemName: "briefcase.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(YPColor.accent)
                                            .frame(width: 36, height: 44)
                                    }
                                } else {
                                    Button {
                                        selectedPortfolioStock = stock
                                    } label: {
                                        Image(systemName: "briefcase")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.gray)
                                            .frame(width: 36, height: 44)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if stock.id != suggestions.prefix(10).last?.id {
                                Divider().padding(.leading, 14)
                            }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .task(id: searchCode) {
            await filterStocksDebounced()
        }
        .navigationDestination(item: $selectedStock) { stock in
            StockDetailView(code: stock.code, name: stock.name)
        }
    }

    private var aShareContent: some View {
        VStack(spacing: 16) {
            hotSectorsHorizontalSection
            fundFlowSection
            deepModulesSection
            moreMenuSection
        }
    }

    // MARK: - 热门板块

    private var hotSectorsHorizontalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView(icon: "flame", title: "热门板块", color: YPColor.hot)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if hotSectors.isEmpty {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.tertiarySystemFill))
                                .frame(width: 140, height: 110)
                        }
                    } else {
                        ForEach(Array(hotSectors.prefix(10).enumerated()), id: \.element.id) { index, sector in
                            NavigationLink {
                                SectorDetailView(sector: sector, isConcept: false)
                            } label: {
                                HotSectorHorizontalCard(sector: sector, rank: index + 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - 资金流向

    private var fundFlowSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView(icon: "arrow.up.arrow.down.circle", title: "资金流向", color: YPColor.accent)

            Picker("资金流向", selection: $selectedFundFlowTab) {
                ForEach(FundFlowTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch selectedFundFlowTab {
                case .north:
                    northFlowContent
                case .industry:
                    sectorFlowContent(sectors: industryFlow, isConcept: false)
                case .concept:
                    sectorFlowContent(sectors: conceptFlow, isConcept: true)
                }
            }
        }
    }

    private var northFlowContent: some View {
        Group {
            if let today = hsgtFlow.first {
                let yesterday = hsgtFlow.count > 1 ? hsgtFlow[1] : nil
                let todayNet = today.northMoney ?? 0
                let yesterdayNet = yesterday?.northMoney ?? 0
                let dailyChange = todayNet - yesterdayNet

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        flowDetailItem(title: "今日合计", value: today.northMoneyFormatted, color: .primary)
                        flowDetailItem(title: "日变化", value: String(format: "%+.1f亿", dailyChange / 10000.0), color: dailyChange >= 0 ? YPColor.up : YPColor.down)
                    }

                    HStack(spacing: 10) {
                        flowDetailItem(title: "沪股通", value: formatFlow(today.hgt), color: (today.hgt ?? 0) >= 0 ? YPColor.up : YPColor.down)
                        flowDetailItem(title: "深股通", value: formatFlow(today.sgt), color: (today.sgt ?? 0) >= 0 ? YPColor.up : YPColor.down)
                    }
                }
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                PlaceholderCard(
                    icon: "arrow.up.arrow.down",
                    title: "暂无数据",
                    description: "北向资金数据暂时为空",
                    color: YPColor.accent
                )
            }
        }
    }

    private func sectorFlowContent(sectors: [SectorMoneyflowData], isConcept: Bool) -> some View {
        Group {
            if sectors.isEmpty {
                PlaceholderCard(
                    icon: "chart.pie",
                    title: "暂无数据",
                    description: "板块资金流向数据暂时为空",
                    color: YPColor.accent
                )
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(sectors.prefix(5).enumerated()), id: \.element.id) { index, sector in
                        NavigationLink {
                            SectorDetailView(sector: sector, isConcept: isConcept)
                        } label: {
                            SectorRow(
                                index: index,
                                name: sector.name,
                                leadStock: sector.leadStock,
                                pctChange: sector.pctChange,
                                netAmount: sector.netAmount
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func flowDetailItem(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func formatFlow(_ value: Double?) -> String {
        guard let value else { return "--" }
        return String(format: "%.1f亿", value / 10000.0)
    }

    // MARK: - 深度复盘

    private var deepModulesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView(icon: "square.3.layers.3d.down.forward", title: "深度复盘", color: YPColor.ai)

            VStack(spacing: 8) {
                NavigationLink { LimitUpLadderView() } label: {
                    MarketMenuRow(icon: "arrow.up.circle.fill", title: "涨停梯队", subtitle: "连板天梯与涨停概念", color: YPColor.up)
                }
                .buttonStyle(.plain)

                NavigationLink { TopListView() } label: {
                    MarketMenuRow(icon: "trophy.circle.fill", title: "龙虎榜", subtitle: "异动个股与机构席位", color: YPColor.warning)
                }
                .buttonStyle(.plain)

                NavigationLink { UnusualMovesView() } label: {
                    MarketMenuRow(icon: "bolt.circle.fill", title: "个股异动", subtitle: "涨跌停、大单买入等异常变动", color: YPColor.brandCyan)
                }
                .buttonStyle(.plain)

                NavigationLink { SectorCorrelationView() } label: {
                    MarketMenuRow(icon: "link.circle.fill", title: "板块关联", subtitle: "板块联动与资金轮动", color: YPColor.info)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 更多菜单

    private var moreMenuSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView(icon: "ellipsis.circle", title: "更多", color: .secondary)

            VStack(spacing: 8) {
                NavigationLink { IndicesListView() } label: {
                    MarketMenuRow(icon: "globe.asia.australia.fill", title: "大盘指数", subtitle: "国内及全球主要指数", color: YPColor.market)
                }
                .buttonStyle(.plain)

                NavigationLink { AllSectorsView() } label: {
                    MarketMenuRow(icon: "square.grid.3x3", title: "全部板块", subtitle: "行业/概念板块排行", color: YPColor.hot)
                }
                .buttonStyle(.plain)

                NavigationLink { SectorMoneyflowTrendView() } label: {
                    MarketMenuRow(icon: "chart.pie.fill", title: "资金流动态趋势", subtitle: "按天查看板块资金净流入趋势", color: YPColor.ai)
                }
                .buttonStyle(.plain)

                NavigationLink { SectorIntradayFlowView() } label: {
                    MarketMenuRow(icon: "waveform.path.ecg", title: "分时资金流向", subtitle: "概念板块实时资金流向", color: YPColor.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 数据加载

    private func loadStockBasics() async {
        allStocks = StockListCacheService.load()
        guard StockListCacheService.shouldRefresh() else { return }

        isLoadingStocks = true
        defer { isLoadingStocks = false }

        do {
            let stocks = try await StockService.fetchStockBasics()
            StockListCacheService.save(stocks)
            allStocks = stocks
        } catch {
            print("加载股票列表失败: \(error.localizedDescription)")
        }
    }

    private func loadMarketData(forceRefresh: Bool = false) async {
        isLoadingData = true
        defer { isLoadingData = false }

        let policy: CachePolicy = forceRefresh ? .skipCache : .default

        async let sectorsTask = StockService.fetchSectorMoneyflow(sectorType: .industry, limit: 12, policy: policy)
        async let industryTask = StockService.fetchSectorMoneyflow(sectorType: .industry, limit: 8, policy: policy)
        async let conceptTask = StockService.fetchSectorMoneyflow(sectorType: .concept, limit: 8, policy: policy)
        async let hsgtTask = MarketService.fetchHsgtFlow(limit: 5, policy: policy)

        do {
            let resp = try await sectorsTask
            hotSectors = resp.sectors
        } catch { if error is CancellationError { return }; print("[Market] 热门板块加载失败: \(error)") }

        do {
            let resp = try await industryTask
            industryFlow = resp.sectors
        } catch { if error is CancellationError { return }; print("[Market] 行业资金加载失败: \(error)") }

        do {
            let resp = try await conceptTask
            conceptFlow = resp.sectors
        } catch { if error is CancellationError { return }; print("[Market] 概念资金加载失败: \(error)") }

        do { hsgtFlow = try await hsgtTask } catch { if error is CancellationError { return }; print("[Market] 北向资金加载失败: \(error)") }
    }

    private func filterStocksDebounced() async {
        let query = searchCode.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            filteredStocks = []
            return
        }

        try? await Task.sleep(nanoseconds: 150_000_000)

        let lowercasedQuery = query.lowercased()
        filteredStocks = allStocks.filter { stock in
            let codeMatch = stock.code.lowercased().hasPrefix(lowercasedQuery)
            let nameMatch = stock.name.lowercased().contains(lowercasedQuery)
            let pinyinMatch = stock.cnspell?.lowercased().hasPrefix(lowercasedQuery) ?? false
            return codeMatch || nameMatch || pinyinMatch
        }
    }

    private func toggleWatchlist(stock: StockBasicInfo) {
        if watchlistCodes.contains(stock.code) {
            WatchlistService.remove(code: stock.code)
            watchlistCodes.remove(stock.code)
            limitErrorMessage = nil
        } else {
            let added = WatchlistService.add(code: stock.code, name: stock.name)
            if added {
                watchlistCodes.insert(stock.code)
                limitErrorMessage = nil
            } else {
                limitErrorMessage = "自选股最多 20 只，建议精简票池后再添加"
            }
        }
    }

    private func loadPortfolioCodes() async {
        do {
            let portfolio = try await StockService.fetchPortfolio()
            portfolioItems = portfolio
            portfolioCodes = Set(portfolio.map(\.code))
        } catch {
            if error is CancellationError { return }
            print("[Market] 加载持仓失败: \(error.localizedDescription)")
        }
    }

    private func removeFromPortfolio(stock: StockBasicInfo) async {
        do {
            try await StockService.removeFromPortfolio(code: stock.code)
            await loadPortfolioCodes()
        } catch {
            if error is CancellationError { return }
            print("[Market] 删除持仓失败: \(error.localizedDescription)")
        }
    }

    private func togglePortfolio(stock: StockBasicInfo) {
        selectedPortfolioStock = stock
    }

    private func portfolioItem(for stock: StockBasicInfo) -> PortfolioItem? {
        portfolioItems.first { $0.code == stock.code }
    }
}

#Preview {
    MarketView()
}
