import SwiftUI

struct WatchlistView: View {
    @State private var watchlist: [StockData] = []
    @State private var portfolio: [PortfolioItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var filterMode: FilterMode = .all

    @State private var selectedStockForPortfolio: StockData?
    @State private var showingPortfolioImport = false

    private enum FilterMode: String, CaseIterable {
        case all = "全部自选"
        case portfolio = "我的持仓"
    }

    private static let maxPreviewCount = 5

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    filterPicker
                    myStocksSection
                    dailyReviewSection
                    aiPositionAdviceSection
                }
                .padding()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("自选")
            .refreshable {
                await loadWatchlist()
            }
            .task {
                await loadWatchlist()
            }
            .sheet(item: $selectedStockForPortfolio) { stock in
                PortfolioEditSheet(
                    code: stock.code,
                    name: stock.name,
                    existingItem: portfolioItem(for: stock),
                    onSave: { Task { await loadWatchlist() } }
                )
            }
            .sheet(isPresented: $showingPortfolioImport) {
                PortfolioImportView {
                    Task { await loadWatchlist() }
                }
            }
        }
    }

    private var filterPicker: some View {
        Picker("筛选", selection: $filterMode) {
            ForEach(FilterMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - 我的股票

    private var myStocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                SectionHeaderView(
                    icon: filterMode == .portfolio ? "briefcase.fill" : "star.fill",
                    title: sectionTitle,
                    color: filterMode == .portfolio ? YPColor.accent : YPColor.warning
                )

                if filterMode == .portfolio {
                    Button {
                        showingPortfolioImport = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.viewfinder")
                                .font(.caption2)
                            Text("截图导入")
                                .font(.caption2)
                        }
                        .foregroundStyle(YPColor.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(YPColor.accent.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }

                Spacer()
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(YPColor.up)
            }

            if displayedStocks.isEmpty && !isLoading {
                VStack(spacing: 8) {
                    Image(systemName: filterMode == .portfolio ? "briefcase" : "star.slash")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text(emptyTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(emptyDescription)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(previewStocks) { stock in
                        NavigationLink(value: stock) {
                            watchlistRow(stock: stock)
                        }
                        .buttonStyle(.plain)
                    }

                    if displayedStocks.count > Self.maxPreviewCount {
                        NavigationLink {
                            WatchlistAllView(
                                title: sectionTitle,
                                stocks: displayedStocks,
                                portfolio: portfolio,
                                onUpdate: { Task { await loadWatchlist() } }
                            )
                        } label: {
                            HStack {
                                Spacer()
                                Text("查看全部 \(displayedStocks.count) 只")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(YPColor.accent)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(YPColor.accent)
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationDestination(for: StockData.self) { stock in
            StockDetailView(code: stock.code, name: stock.name)
        }
    }

    private var sectionTitle: String {
        filterMode == .portfolio ? "我的持仓" : "我的股票"
    }

    private var emptyTitle: String {
        filterMode == .portfolio ? "暂无持仓" : "暂无自选股"
    }

    private var emptyDescription: String {
        filterMode == .portfolio ? "在股票详情页标记持仓" : "在市场页面搜索并添加关注的股票"
    }

    private var displayedStocks: [StockData] {
        let portfolioCodes = Set(portfolio.map(\.code))
        switch filterMode {
        case .all:
            return watchlist
        case .portfolio:
            return watchlist.filter { portfolioCodes.contains($0.code) }
        }
    }

    private var previewStocks: [StockData] {
        Array(displayedStocks.prefix(Self.maxPreviewCount))
    }

    private func portfolioItem(for stock: StockData) -> PortfolioItem? {
        portfolio.first { $0.code == stock.code }
    }

    private func watchlistRow(stock: StockData) -> some View {
        let item = portfolioItem(for: stock)
        let isPortfolioMode = filterMode == .portfolio

        return HStack(alignment: .center, spacing: 10) {
            // 左侧：名称、代码、成本/数量
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(stock.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if item?.isMargin == true {
                        Text("融")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(YPColor.up.opacity(0.12))
                            .foregroundStyle(YPColor.up)
                            .clipShape(Capsule())
                    }
                }

                Text(stock.code)
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                if isPortfolioMode, let item {
                    Group {
                        if item.hasPositionDetails {
                            Text("成本 \(String(format: "%.3f", item.costPrice ?? 0)) · \(String(format: "%.0f", item.quantity ?? 0))股")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("未设置成本/数量")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 2)
                    .lineLimit(1)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            // 中间：盈亏（仅在持仓模式且有详情时）
            if isPortfolioMode, let item, item.hasPositionDetails {
                if let pnl = item.unrealizedPnL(at: stock.price),
                   let pnlPercent = item.pnlPercent(at: stock.price) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%+.2f", pnl))
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("(\(String(format: "%+.2f%%", pnlPercent)))")
                            .font(.caption2)
                    }
                    .foregroundStyle(pnl >= 0 ? YPColor.up : YPColor.down)
                    .frame(minWidth: 64, alignment: .trailing)
                    .lineLimit(1)
                }
            }

            // 右侧：价格、涨跌幅
            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "%.2f", stock.price))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(stock.changePercent >= 0 ? YPColor.up : YPColor.down)
                    .lineLimit(1)

                Text(String(format: "%+.2f%%", stock.changePercent))
                    .font(.caption)
                    .foregroundStyle(stock.changePercent >= 0 ? YPColor.up : YPColor.down)
                    .lineLimit(1)
            }
            .frame(minWidth: 56, alignment: .trailing)

            // 操作按钮
            HStack(spacing: 6) {
                Button {
                    Task { await toggleWatchlist(stock: stock) }
                } label: {
                    Image(systemName: "star.fill")
                        .font(.subheadline)
                        .foregroundStyle(YPColor.warning)
                        .frame(width: 28, height: 32)
                }
                .buttonStyle(.plain)

                Button {
                    Task { await togglePortfolio(stock: stock) }
                } label: {
                    Image(systemName: isInPortfolio(stock: stock) ? "briefcase.fill" : "briefcase")
                        .font(.subheadline)
                        .foregroundStyle(isInPortfolio(stock: stock) ? YPColor.accent : Color.gray)
                        .frame(width: 28, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                selectedStockForPortfolio = stock
            } label: {
                Label(
                    isInPortfolio(stock: stock) ? "编辑持仓" : "添加持仓",
                    systemImage: isInPortfolio(stock: stock) ? "pencil" : "briefcase.fill"
                )
            }
            if isInPortfolio(stock: stock) {
                Button(role: .destructive) {
                    Task { await togglePortfolio(stock: stock) }
                } label: {
                    Label("删除持仓", systemImage: "trash")
                }
            }
        }
    }

    private func isInPortfolio(stock: StockData) -> Bool {
        portfolio.contains { $0.code == stock.code }
    }

    private func toggleWatchlist(stock: StockData) async {
        WatchlistService.remove(code: stock.code)
        await loadWatchlist()
    }

    private func togglePortfolio(stock: StockData) async {
        do {
            if isInPortfolio(stock: stock) {
                try await StockService.removeFromPortfolio(code: stock.code)
            } else {
                _ = try await StockService.addToPortfolio(code: stock.code, name: stock.name)
            }
            portfolio = try await StockService.fetchPortfolio()
        } catch {
            if error is CancellationError { return }
            errorMessage = "操作持仓失败: \(error.localizedDescription)"
        }
    }

    // MARK: - 每日自动复盘

    private var dailyReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "calendar.badge.clock", title: "每日自动复盘", color: YPColor.accent)

            NavigationLink(destination: DailyReviewView()) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.title3)
                            .foregroundStyle(YPColor.accent)
                            .frame(width: 40, height: 40)
                            .background(YPColor.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("AI 每日复盘")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("基于自选股生成每日收盘复盘报告")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.quaternary)
                    }

                    HStack(spacing: 6) {
                        Text("会员专属")
                            .font(.caption2)
                            .foregroundStyle(YPColor.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(YPColor.accent.opacity(0.08))
                            .clipShape(Capsule())

                        Spacer()

                        Label("查看复盘", systemImage: "sparkles")
                            .font(.caption2)
                            .foregroundStyle(YPColor.brandPurple)
                    }
                }
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - AI 仓位建议

    private var aiPositionAdviceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "brain", title: "AI 仓位建议", color: YPColor.ai)

            NavigationLink(destination: PositionAdviceView()) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.pie")
                            .font(.title3)
                            .foregroundStyle(YPColor.ai)
                            .frame(width: 40, height: 40)
                            .background(YPColor.ai.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("AI 仓位建议")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("基于持仓和市场情绪，智能建议仓位配比")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.quaternary)
                    }

                    HStack(spacing: 6) {
                        Text("会员 / 积分")
                            .font(.caption2)
                            .foregroundStyle(YPColor.ai)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(YPColor.ai.opacity(0.08))
                            .clipShape(Capsule())

                        Spacer()

                        Label("查看建议", systemImage: "sparkles")
                            .font(.caption2)
                            .foregroundStyle(YPColor.brandPurple)
                    }
                }
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 数据加载

    private func loadWatchlist() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // 独立加载自选和持仓，避免一个失败导致另一个也不显示
        var fetchedWatchlist: [StockData] = []
        var fetchedPortfolio: [PortfolioItem] = []

        do {
            fetchedWatchlist = try await StockService.fetchWatchlist()
        } catch APIError.unauthorized {
            errorMessage = "未登录"
            return
        } catch {
            if error is CancellationError { return }
            errorMessage = "加载自选失败: \(error.localizedDescription)"
            return
        }

        do {
            fetchedPortfolio = try await StockService.fetchPortfolio()
        } catch {
            if !(error is CancellationError) {
                print("[Watchlist] 加载持仓失败: \(error.localizedDescription)")
            }
        }

        portfolio = fetchedPortfolio

        // 确保持仓中的股票也有行情数据（即使不在自选列表中）
        let watchlistCodes = Set(fetchedWatchlist.map(\.code))
        let missingPortfolioCodes = fetchedPortfolio.map(\.code).filter { !watchlistCodes.contains($0) }
        if missingPortfolioCodes.isEmpty {
            watchlist = fetchedWatchlist
        } else {
            let codes = missingPortfolioCodes.joined(separator: ",")
            var extraQuotes: [StockData] = []
            do {
                extraQuotes = try await StockService.fetchQuotesBatch(codes: codes)
            } catch {
                extraQuotes = await withTaskGroup(of: StockData?.self) { group in
                    for code in missingPortfolioCodes {
                        group.addTask { try? await StockService.fetchQuote(code: code) }
                    }
                    var results: [StockData] = []
                    for await result in group {
                        if let r = result { results.append(r) }
                    }
                    return results
                }
            }
            watchlist = fetchedWatchlist + extraQuotes
        }
    }
}

#Preview {
    WatchlistView()
}

// MARK: - 全部自选/持仓列表页

struct WatchlistAllView: View {
    let title: String
    let stocks: [StockData]
    let portfolio: [PortfolioItem]
    let onUpdate: () -> Void

    @State private var currentStocks: [StockData] = []
    @State private var currentPortfolio: [PortfolioItem] = []
    @State private var selectedStockForPortfolio: StockData?

    private var isPortfolioMode: Bool { title == "我的持仓" }

    init(title: String, stocks: [StockData], portfolio: [PortfolioItem], onUpdate: @escaping () -> Void) {
        self.title = title
        self.stocks = stocks
        self.portfolio = portfolio
        self.onUpdate = onUpdate
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(currentStocks) { stock in
                    NavigationLink {
                        StockDetailView(code: stock.code, name: stock.name)
                    } label: {
                        watchlistRow(stock: stock)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            currentStocks = stocks
            currentPortfolio = portfolio
        }
        .sheet(item: $selectedStockForPortfolio) { stock in
            PortfolioEditSheet(
                code: stock.code,
                name: stock.name,
                existingItem: portfolioItem(for: stock),
                onSave: { Task { await refreshPortfolio() } }
            )
        }
    }

    private func portfolioItem(for stock: StockData) -> PortfolioItem? {
        currentPortfolio.first { $0.code == stock.code }
    }

    private func watchlistRow(stock: StockData) -> some View {
        let item = portfolioItem(for: stock)

        return HStack(alignment: .center, spacing: 10) {
            // 左侧：名称、代码、成本/数量
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(stock.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if item?.isMargin == true {
                        Text("融")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(YPColor.up.opacity(0.12))
                            .foregroundStyle(YPColor.up)
                            .clipShape(Capsule())
                    }
                }

                Text(stock.code)
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                if isPortfolioMode, let item {
                    Group {
                        if item.hasPositionDetails {
                            Text("成本 \(String(format: "%.3f", item.costPrice ?? 0)) · \(String(format: "%.0f", item.quantity ?? 0))股")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("未设置成本/数量")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 2)
                    .lineLimit(1)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            // 中间：盈亏（仅在持仓模式且有详情时）
            if isPortfolioMode, let item, item.hasPositionDetails {
                if let pnl = item.unrealizedPnL(at: stock.price),
                   let pnlPercent = item.pnlPercent(at: stock.price) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%+.2f", pnl))
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("(\(String(format: "%+.2f%%", pnlPercent)))")
                            .font(.caption2)
                    }
                    .foregroundStyle(pnl >= 0 ? YPColor.up : YPColor.down)
                    .frame(minWidth: 64, alignment: .trailing)
                    .lineLimit(1)
                }
            }

            // 右侧：价格、涨跌幅
            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "%.2f", stock.price))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(stock.changePercent >= 0 ? YPColor.up : YPColor.down)
                    .lineLimit(1)

                Text(String(format: "%+.2f%%", stock.changePercent))
                    .font(.caption)
                    .foregroundStyle(stock.changePercent >= 0 ? YPColor.up : YPColor.down)
                    .lineLimit(1)
            }
            .frame(minWidth: 56, alignment: .trailing)

            // 操作按钮
            HStack(spacing: 6) {
                Button {
                    Task { await toggleWatchlist(stock: stock) }
                } label: {
                    Image(systemName: "star.fill")
                        .font(.subheadline)
                        .foregroundStyle(YPColor.warning)
                        .frame(width: 28, height: 32)
                }
                .buttonStyle(.plain)

                Button {
                    Task { await togglePortfolio(stock: stock) }
                } label: {
                    Image(systemName: isInPortfolio(stock: stock) ? "briefcase.fill" : "briefcase")
                        .font(.subheadline)
                        .foregroundStyle(isInPortfolio(stock: stock) ? YPColor.accent : Color.gray)
                        .frame(width: 28, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                selectedStockForPortfolio = stock
            } label: {
                Label(
                    isInPortfolio(stock: stock) ? "编辑持仓" : "添加持仓",
                    systemImage: isInPortfolio(stock: stock) ? "pencil" : "briefcase.fill"
                )
            }
            if isInPortfolio(stock: stock) {
                Button(role: .destructive) {
                    Task { await togglePortfolio(stock: stock) }
                } label: {
                    Label("删除持仓", systemImage: "trash")
                }
            }
        }
    }

    private func isInPortfolio(stock: StockData) -> Bool {
        currentPortfolio.contains { $0.code == stock.code }
    }

    private func toggleWatchlist(stock: StockData) async {
        WatchlistService.remove(code: stock.code)
        currentStocks.removeAll { $0.code == stock.code }
        onUpdate()
    }

    private func togglePortfolio(stock: StockData) async {
        do {
            if isInPortfolio(stock: stock) {
                try await StockService.removeFromPortfolio(code: stock.code)
            } else {
                _ = try await StockService.addToPortfolio(code: stock.code, name: stock.name)
            }
            await refreshPortfolio()
        } catch {
            if error is CancellationError { return }
            print("[WatchlistAll] 切换持仓失败: \(error.localizedDescription)")
        }
    }

    private func refreshPortfolio() async {
        do {
            currentPortfolio = try await StockService.fetchPortfolio()
            onUpdate()
        } catch {
            print("[WatchlistAll] 刷新持仓失败: \(error.localizedDescription)")
        }
    }
}
