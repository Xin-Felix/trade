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
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        searchSection
                        marketToolsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("行情")
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

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("股票搜索")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    TextField("输入股票代码或名称，如 000001 / 平安", text: $searchCode)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.search)
                        .focused($isSearchFieldFocused)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    if isLoadingStocks {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 44, height: 44)
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
                                        .padding()
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        toggleWatchlist(stock: stock)
                                    } label: {
                                        Image(systemName: watchlistCodes.contains(stock.code) ? "star.fill" : "star")
                                            .font(.subheadline)
                                            .foregroundStyle(watchlistCodes.contains(stock.code) ? .yellow : .secondary)
                                            .frame(width: 44, height: 44)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .background(Color(.secondarySystemBackground))

                                if stock.id != suggestions.prefix(10).last?.id {
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.top, 4)
                    } else if !isLoadingStocks {
                        Text("未找到匹配的股票")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
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

    private func loadStockBasics() async {
        // 先读本地缓存展示，如果过期再去后台刷新
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

        // 简单防抖，避免快速输入时频繁过滤
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

    private var marketToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("市场工具")
                .font(.headline)
                .foregroundStyle(.primary)

            NavigationLink {
                SectorMoneyflowView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "chart.pie.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 44, height: 44)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("板块资金流向")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Text("查看行业/概念板块资金净流入排行")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - 板块资金流向详情页

struct SectorMoneyflowView: View {
    @State private var selectedType: SectorMoneyflowType = .industry
    @State private var selectedSort: SectorMoneyflowSort = .netAmount
    @State private var selectedDate = Date()
    @State private var sectors: [SectorMoneyflowData] = []
    @State private var tradeDate: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    trendEntryLink
                    typePicker
                    datePicker
                    sortPicker

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if isLoading && sectors.isEmpty {
                        ProgressView()
                            .scaleEffect(1.2)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        sectorsList
                    }
                }
                .padding()
            }
        }
        .navigationTitle("板块资金流向")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadSectorMoneyflow()
        }
        .onChange(of: selectedType) { _, _ in
            Task { await loadSectorMoneyflow() }
        }
        .onChange(of: selectedSort) { _, _ in
            Task { await loadSectorMoneyflow() }
        }
        .onChange(of: selectedDate) { _, _ in
            Task { await loadSectorMoneyflow() }
        }
    }

    private var trendEntryLink: some View {
        NavigationLink {
            SectorMoneyflowTrendView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text("资金流动态趋势")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("查看时间段内板块资金流向变化")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var typePicker: some View {
        Picker("板块类型", selection: $selectedType) {
            Text("行业").tag(SectorMoneyflowType.industry)
            Text("概念").tag(SectorMoneyflowType.concept)
        }
        .pickerStyle(.segmented)
    }

    private var datePicker: some View {
        HStack {
            Text("日期")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            DatePicker(
                "",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .frame(maxWidth: 120)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var sortPicker: some View {
        HStack {
            Text("排序")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Picker("排序", selection: $selectedSort) {
                ForEach(SectorMoneyflowSort.allCases) { sort in
                    Text(sort.title).tag(sort)
                }
            }
            .pickerStyle(.menu)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var sectorsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !tradeDate.isEmpty {
                HStack {
                    Text("数据日期: \(formatTradeDate(tradeDate))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("共 \(sectors.count) 个板块")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            LazyVStack(spacing: 8) {
                ForEach(sectors) { sector in
                    SectorMoneyflowRow(sector: sector)
                }
            }
        }
    }

    private func loadSectorMoneyflow() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await StockService.fetchSectorMoneyflow(
                sectorType: selectedType,
                tradeDate: dateFormatter.string(from: selectedDate),
                sortBy: selectedSort.rawValue,
                limit: 50
            )
            sectors = response.sectors
            tradeDate = response.tradeDate
        } catch APIError.unauthorized {
            errorMessage = "未登录，请重新登录"
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
        }
    }

    private func formatTradeDate(_ dateString: String) -> String {
        guard dateString.count == 8 else { return dateString }
        let year = dateString.prefix(4)
        let month = dateString.dropFirst(4).prefix(2)
        let day = dateString.suffix(2)
        return "\(year)-\(month)-\(day)"
    }
}

enum SectorMoneyflowSort: String, CaseIterable, Identifiable {
    case netAmount = "net_amount"
    case pctChange = "pct_change"
    case netAmountAsc = "net_amount_asc"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .netAmount: return "净流入 ↓"
        case .pctChange: return "涨跌幅 ↓"
        case .netAmountAsc: return "净流入 ↑"
        }
    }
}

struct SectorMoneyflowRow: View {
    let sector: SectorMoneyflowData

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(sector.name ?? "未知板块")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                if let leadStock = sector.leadStock {
                    Text("龙头: \(leadStock)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let netAmount = sector.netAmount {
                    Text(String(format: "%.2f亿", netAmount))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(netAmount >= 0 ? .red : .green)
                }

                if let pctChange = sector.pctChange {
                    Text(String(format: "%.2f%%", pctChange))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(pctChange >= 0 ? .red : .green)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    MarketView()
}
