import SwiftUI

struct WatchlistView: View {
    @State private var watchlist: [StockData] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
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

    // MARK: - 我的股票

    private var myStocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeaderView(icon: "star.fill", title: "我的股票", color: YPColor.warning)
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

            if watchlist.isEmpty && !isLoading {
                VStack(spacing: 8) {
                    Image(systemName: "star.slash")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("暂无自选股")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("在市场页面搜索并添加关注的股票")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(watchlist) { stock in
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

            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "%.2f", stock.price))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(stock.changePercent >= 0 ? YPColor.up : YPColor.down)
                Text(String(format: "%+.2f%%", stock.changePercent))
                    .font(.caption)
                    .foregroundStyle(stock.changePercent >= 0 ? YPColor.up : YPColor.down)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - 每日自动复盘

    private var dailyReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "calendar.badge.clock", title: "每日自动复盘", color: YPColor.accent)
            PlaceholderCard(icon: "doc.text.magnifyingglass", description: "AI 自动分析持仓表现，生成每日复盘报告", color: YPColor.accent)
        }
    }

    // MARK: - AI 仓位建议

    private var aiPositionAdviceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "brain", title: "AI 仓位建议", color: YPColor.ai)
            PlaceholderCard(icon: "chart.pie", description: "基于市场情绪和持仓分析，智能建议仓位配比", color: YPColor.ai)
        }
    }

    // MARK: - 数据加载

    private func loadWatchlist() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            watchlist = try await StockService.fetchWatchlist()
        } catch APIError.unauthorized {
            errorMessage = "未登录"
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
        }
    }
}

#Preview {
    WatchlistView()
}
