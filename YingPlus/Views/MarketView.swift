import SwiftUI

struct MarketView: View {
    @State private var searchCode = ""
    @State private var allStocks: [StockBasicInfo] = []
    @State private var filteredStocks: [StockBasicInfo] = []
    @State private var isLoadingStocks = false
    @State private var selectedStock: StockBasicInfo?
    @State private var watchlistCodes: Set<String> = []
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    searchSection
                    marketOverviewEntrySection
                    sectorCenterSection
                    featureModulesSection
                }
                .padding()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("市场")
            .refreshable {
                await loadStockBasics()
                watchlistCodes = Set(WatchlistService.load().map(\.code))
            }
            .task {
                await loadStockBasics()
                watchlistCodes = Set(WatchlistService.load().map(\.code))
            }
        }
    }

    // MARK: - 搜索

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                                        .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.plain)
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

    // MARK: - 市场概览入口

    private var marketOverviewEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "chart.bar", title: "市场概览", color: YPColor.accent)

            NavigationLink {
                IndicesListView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "globe.asia.australia.fill")
                        .font(.title3)
                        .foregroundStyle(YPColor.accent)
                        .frame(width: 40, height: 40)
                        .background(YPColor.accent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("大盘指数")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        Text("查看国内及全球主要指数走势")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.quaternary)
                }
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 板块中心

    private var sectorCenterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "square.grid.3x3", title: "板块中心", color: YPColor.ai)

            NavigationLink {
                SectorMoneyflowTrendView()
            } label: {
                sectorEntryRow(
                    icon: "chart.pie.fill",
                    title: "每日资金流向",
                    subtitle: "按天查看行业/概念板块资金净流入趋势",
                    color: YPColor.ai
                )
            }

            NavigationLink {
                SectorIntradayFlowView()
            } label: {
                sectorEntryRow(
                    icon: "waveform.path.ecg",
                    title: "分时资金流向",
                    subtitle: "概念板块实时资金流入/流出分时数据",
                    color: YPColor.accent
                )
            }
        }
    }

    private func sectorEntryRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 功能板块（图标网格）

    private var featureModulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "square.grid.2x2", title: "功能板块", color: YPColor.info)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                featureButton(
                    icon: "arrow.up.circle.fill",
                    title: "涨停梯队",
                    color: YPColor.up
                ) {
                    LimitUpLadderView()
                }

                featureButton(
                    icon: "trophy.circle.fill",
                    title: "龙虎榜",
                    color: YPColor.warning
                ) {
                    TopListView()
                }

                featureButton(
                    icon: "bolt.circle.fill",
                    title: "个股异动",
                    color: YPColor.brandCyan
                ) {
                    UnusualMovesView()
                }

                featureButton(
                    icon: "link.circle.fill",
                    title: "板块关联",
                    color: YPColor.info
                ) {
                    SectorCorrelationView()
                }
            }
        }
    }

    private func featureButton<Destination: View>(
        icon: String,
        title: String,
        color: Color,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func skeletonBar(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(.tertiarySystemFill))
            .frame(width: width, height: height)
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
        } else {
            WatchlistService.add(code: stock.code, name: stock.name)
            watchlistCodes.insert(stock.code)
        }
    }
}

// MARK: - 龙虎榜详情页

struct TopListView: View {
    @State private var topListItems: [TopListItem] = []
    @State private var isLoading = false
    @State private var loadError: Error?
    @State private var selectedDate: Date
    @State private var isDatePickerPresented = false

    init() {
        _selectedDate = State(initialValue: TopListView.latestTradeDate())
    }

    private static let requestFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let date = topListItems.first?.tradeDate {
                    tradeDateHeader(date)
                }

                if isLoading && topListItems.isEmpty {
                    loadingList
                } else if let error = loadError {
                    errorState(error)
                } else if topListItems.isEmpty {
                    PlaceholderCard(
                        icon: "trophy.circle",
                        title: "暂无数据",
                        description: "暂无龙虎榜数据",
                        color: YPColor.warning
                    )
                } else {
                    topListContent
                }
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("龙虎榜")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isDatePickerPresented = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(displayDate(selectedDate))
                            .font(.subheadline)
                    }
                    .foregroundStyle(YPColor.warning)
                }
            }
        }
        .refreshable { await loadData(forceRefresh: true) }
        .task { await loadData() }
        .sheet(isPresented: $isDatePickerPresented) {
            datePickerSheet
        }
    }

    private var topListContent: some View {
        LazyVStack(spacing: 10) {
            ForEach(topListItems) { item in
                NavigationLink {
                    StockDetailView(code: item.tsCode, name: item.name ?? item.tsCode)
                } label: {
                    topListCard(item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func topListCard(_ item: TopListItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name ?? item.tsCode)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(item.tsCode)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if let pct = item.pctChange {
                    Text(String(format: "%+.2f%%", pct))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(pct >= 0 ? YPColor.up : YPColor.down)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            HStack(spacing: 16) {
                metricItem(title: "净买入", value: item.netAmountFormatted, color: (item.netAmount ?? 0) >= 0 ? YPColor.up : YPColor.down)

                if let turnover = item.turnoverRate {
                    metricItem(title: "换手率", value: String(format: "%.2f%%", turnover))
                }

                if let amount = item.amount {
                    metricItem(title: "成交额", value: formatAmount(amount))
                }

                Spacer()
            }

            if let reason = item.reason, !reason.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb")
                        .font(.caption2)
                        .foregroundStyle(YPColor.warning)
                    Text(reason)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func metricItem(title: String, value: String, color: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color ?? .primary)
        }
    }

    private func formatAmount(_ amount: Double) -> String {
        if abs(amount) >= 100_000_000 {
            return String(format: "%.2f亿", amount / 100_000_000)
        } else if abs(amount) >= 10_000 {
            return String(format: "%.0f万", amount / 10_000)
        }
        return String(format: "%.0f", amount)
    }

    private var loadingList: some View {
        VStack(spacing: 10) {
            ForEach(0..<6) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 100)
            }
        }
    }

    private func errorState(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(YPColor.warning.opacity(0.8))
            Text("数据加载失败")
                .font(.subheadline)
                .fontWeight(.medium)
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func tradeDateHeader(_ date: String) -> some View {
        HStack {
            Spacer()
            Image(systemName: "calendar")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formatTradeDate(date))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var datePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker(
                    "选择交易日",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()

                Spacer()
            }
            .navigationTitle("选择交易日")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("确定") {
                        isDatePickerPresented = false
                        Task { await loadData(forceRefresh: true) }
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        isDatePickerPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func loadData(forceRefresh: Bool = false) async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        let policy: CachePolicy = forceRefresh ? .skipCache : .default
        let calendar = Calendar.current
        var date = selectedDate

        // 最多回退 5 个交易日请求数据
        for _ in 0..<5 {
            let dateString = Self.requestFormatter.string(from: date)
            do {
                topListItems = try await MarketService.fetchTopList(tradeDate: dateString, limit: 50, policy: policy)
                if !topListItems.isEmpty {
                    selectedDate = date
                    return
                }
            } catch {
                if error is CancellationError { return }
                print("[TopList] \(dateString) 加载失败: \(error.localizedDescription)")
                loadError = error
            }
            date = previousTradeDate(from: date, calendar: calendar)
        }
    }

    private func previousTradeDate(from date: Date, calendar: Calendar) -> Date {
        var previous = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        while Self.isWeekend(previous, calendar: calendar) {
            previous = calendar.date(byAdding: .day, value: -1, to: previous) ?? previous
        }
        return previous
    }

    private func formatTradeDate(_ date: String) -> String {
        guard date.count == 8 else { return date }
        let year = date.prefix(4)
        let month = date[date.index(date.startIndex, offsetBy: 4)..<date.index(date.startIndex, offsetBy: 6)]
        let day = date[date.index(date.startIndex, offsetBy: 6)...]
        return "\(year)-\(month)-\(day)"
    }

    private func displayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter.string(from: date)
    }

    private static func latestTradeDate() -> Date {
        let calendar = Calendar.current
        var date = Date()
        while isWeekend(date, calendar: calendar) {
            date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        }
        return date
    }

    private static func isWeekend(_ date: Date, calendar: Calendar) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }
}

// MARK: - 板块关联分析（占位）

struct SectorCorrelationView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PlaceholderCard(
                    icon: "link.circle",
                    title: "功能开发中",
                    description: "分析板块之间的联动关系和资金轮动",
                    color: YPColor.info
                )
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("板块关联分析")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 个股异动（占位）

struct UnusualMovesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PlaceholderCard(
                    icon: "bolt.circle",
                    title: "功能开发中",
                    description: "涨停、跌停、大单买入等异常变动",
                    color: YPColor.up
                )
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("个股异动")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MarketView()
}
