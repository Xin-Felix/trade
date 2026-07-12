import SwiftUI

struct WatchlistView: View {
    @State private var watchlist: [StockData] = []
    @State private var portfolio: [PortfolioItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var filterMode: FilterMode = .all

    private enum FilterMode: String, CaseIterable {
        case all = "全部自选"
        case portfolio = "我的持仓"
    }

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
            HStack {
                SectionHeaderView(
                    icon: filterMode == .portfolio ? "briefcase.fill" : "star.fill",
                    title: sectionTitle,
                    color: filterMode == .portfolio ? YPColor.accent : YPColor.warning
                )
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
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
                    ForEach(displayedStocks) { stock in
                        NavigationLink(value: stock) {
                            watchlistRow(stock: stock)
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

    private func watchlistRow(stock: StockData) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(stock.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text(stock.code)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(String(format: "%.2f", stock.price))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(stock.changePercent >= 0 ? YPColor.up : YPColor.down)
                    Text(String(format: "%+.2f%%", stock.changePercent))
                        .font(.caption)
                        .foregroundStyle(stock.changePercent >= 0 ? YPColor.up : YPColor.down)
                }

                Button {
                    Task { await togglePortfolio(stock: stock) }
                } label: {
                    Image(systemName: isInPortfolio(stock: stock) ? "briefcase.fill" : "briefcase")
                        .font(.subheadline)
                        .foregroundStyle(isInPortfolio(stock: stock) ? YPColor.accent : Color.gray)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func isInPortfolio(stock: StockData) -> Bool {
        portfolio.contains { $0.code == stock.code }
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
            print("[Watchlist] 切换持仓失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 每日自动复盘

    private var dailyReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "calendar.badge.clock", title: "每日自动复盘", color: YPColor.accent)
            PlaceholderCard(
                icon: "doc.text.magnifyingglass",
                title: "功能开发中",
                description: "AI 自动分析持仓表现，生成每日复盘报告",
                color: YPColor.accent
            )
        }
    }

    // MARK: - AI 仓位建议

    private var aiPositionAdviceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "brain", title: "AI 仓位建议", color: YPColor.ai)
            PlaceholderCard(
                icon: "chart.pie",
                title: "功能开发中",
                description: "基于市场情绪和持仓分析，智能建议仓位配比",
                color: YPColor.ai
            )
        }
    }

    // MARK: - 数据加载

    private func loadWatchlist() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let watchlistTask = StockService.fetchWatchlist()
            async let portfolioTask = StockService.fetchPortfolio()
            watchlist = try await watchlistTask
            portfolio = try await portfolioTask
        } catch APIError.unauthorized {
            errorMessage = "未登录"
        } catch {
            if error is CancellationError { return }
            errorMessage = "加载失败: \(error.localizedDescription)"
        }
    }
}

#Preview {
    WatchlistView()
}
