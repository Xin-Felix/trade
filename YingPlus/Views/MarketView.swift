import SwiftUI

struct MarketView: View {
    @State private var searchCode = ""
    @State private var allStocks: [StockBasicInfo] = []
    @State private var filteredStocks: [StockBasicInfo] = []
    @State private var isLoadingStocks = false
    @State private var selectedStock: StockBasicInfo?
    @State private var watchlistCodes: Set<String> = []
    @State private var topListItems: [TopListItem] = []
    @State private var isLoadingTopList = false
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    searchSection
                    stockQuotesSection
                    sectorCenterSection
                    sectorCorrelationSection
                    topListSection
                    unusualMovesSection
                }
                .padding()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("市场")
            .refreshable {
                await loadStockBasics()
                await loadTopList()
                watchlistCodes = Set(WatchlistService.load().map(\.code))
            }
            .task {
                await loadStockBasics()
                await loadTopList()
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

    // MARK: - 股票行情

    private var stockQuotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "chart.line.uptrend.xyaxis", title: "股票行情", color: YPColor.accent)

            VStack(spacing: 8) {
                ForEach(0..<3) { _ in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            skeletonBar(width: 80, height: 14)
                            skeletonBar(width: 60, height: 12)
                        }
                        Spacer()
                        skeletonBar(width: 60, height: 16)
                        skeletonBar(width: 50, height: 14)
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - 板块中心

    private var sectorCenterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "square.grid.3x3", title: "板块中心", color: YPColor.ai)

            NavigationLink {
                SectorMoneyflowTrendView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "chart.pie.fill")
                        .font(.title3)
                        .foregroundStyle(YPColor.ai)
                        .frame(width: 40, height: 40)
                        .background(YPColor.ai.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("板块资金流向")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        Text("查看行业/概念板块资金净流入排行")
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
        }
    }

    // MARK: - 板块关联分析

    private var sectorCorrelationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "link", title: "板块关联分析", color: YPColor.info)
            PlaceholderCard(icon: "link.circle", description: "分析板块之间的联动关系和资金轮动", color: YPColor.info)
        }
    }

    // MARK: - 龙虎榜

    private var topListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "trophy", title: "龙虎榜", color: YPColor.warning)

            if topListItems.isEmpty && !isLoadingTopList {
                PlaceholderCard(icon: "trophy.circle", description: "暂无龙虎榜数据", color: YPColor.warning)
            } else if isLoadingTopList {
                VStack(spacing: 8) {
                    ForEach(0..<3) { _ in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                skeletonBar(width: 80, height: 14)
                                skeletonBar(width: 60, height: 12)
                            }
                            Spacer()
                            skeletonBar(width: 60, height: 14)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(topListItems.prefix(10)) { item in
                        NavigationLink {
                            StockDetailView(code: item.tsCode, name: item.name ?? item.tsCode)
                        } label: {
                            topListRow(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func topListRow(_ item: TopListItem) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name ?? item.tsCode)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(item.tsCode)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // 涨跌幅
            if let pct = item.pctChange {
                Text(String(format: "%+.2f%%", pct))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(pct >= 0 ? YPColor.up : YPColor.down)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background((pct >= 0 ? YPColor.up : YPColor.down).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            // 净买入
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.netAmountFormatted)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle((item.netAmount ?? 0) >= 0 ? YPColor.up : YPColor.down)
                Text("净买入")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
            .frame(width: 65, alignment: .trailing)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - 个股异动

    private var unusualMovesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "bolt", title: "个股异动", color: YPColor.up)
            PlaceholderCard(icon: "bolt.circle", description: "涨停、跌停、大单买入等异常变动", color: YPColor.up)
        }
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

    private func loadTopList() async {
        isLoadingTopList = true
        defer { isLoadingTopList = false }

        do {
            topListItems = try await MarketService.fetchTopList(limit: 15)
        } catch {
            print("[Market] 龙虎榜加载失败: \(error.localizedDescription)")
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

#Preview {
    MarketView()
}
