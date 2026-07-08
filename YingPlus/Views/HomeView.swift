import SwiftUI

struct HomeView: View {
    @State private var watchlist: [StockData] = []
    @State private var indices: [IndexItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    indexSection
                    watchlistSection
                }
                .padding()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("行情概览")
            .refreshable {
                await loadData()
            }
            .task {
                await loadData()
            }
            .onAppear {
                Task { await loadWatchlist() }
            }
        }
    }

    private func loadData() async {
        await loadIndices()
        await loadWatchlist()
    }

    // MARK: - 大盘指数

    private var indexSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("大盘指数")
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                ForEach(indices) { index in
                    NavigationLink {
                        IndexDetailView(index: index)
                    } label: {
                        VStack(spacing: 6) {
                            Text(index.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.2f", index.value))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            Text(String(format: "%.2f%%", index.change))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(index.change >= 0 ? .red : .green)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 自选股

    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("自选股")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                Button("刷新") {
                    Task { await loadWatchlist() }
                }
                .font(.caption)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.subheadline)
            }

            LazyVStack(spacing: 8) {
                ForEach(watchlist) { stock in
                    NavigationLink(value: stock) {
                        StockRow(stock: stock)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            WatchlistService.remove(code: stock.code)
                            Task { await loadWatchlist() }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }

                if watchlist.isEmpty && !isLoading {
                    Text("暂无自选股，去搜索添加吧")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                }
            }
        }
        .navigationDestination(for: StockData.self) { stock in
            StockDetailView(code: stock.code, name: stock.name)
        }
    }

    private func loadIndices() async {
        do {
            indices = try await StockService.fetchIndices()
        } catch {
            print("加载大盘指数失败: \(error.localizedDescription)")
        }
    }

    private func loadWatchlist() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            watchlist = try await StockService.fetchWatchlist()
        } catch APIError.unauthorized {
            errorMessage = "未登录，无法获取自选股"
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
        }
    }
}

// MARK: - 指数详情页（K 线）

struct IndexDetailView: View {
    let index: IndexItem

    @State private var selectedPeriod: KlinePeriod = .day
    @State private var klines: [KlineData] = []
    @State private var selectedKline: KlineData?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerView
                    periodPicker
                    chartSection
                }
                .padding()
            }
        }
        .navigationTitle(index.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadKlines()
        }
        .onChange(of: selectedPeriod) { _, _ in
            Task { await loadKlines() }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text(index.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Spacer()

                if let selectedKline = selectedKline {
                    Text(selectedKline.tradeDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            let price = selectedKline?.close ?? index.value
            let changePercent = selectedKlineChangePercent

            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text(String(format: "%.2f", price))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(displayColor)

                Text(String(format: "%.2f%%", changePercent))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(displayColor)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var selectedKlineChangePercent: Double {
        guard let selectedKline = selectedKline else {
            return index.change
        }
        guard selectedKline.open != 0 else { return 0 }
        return (selectedKline.close - selectedKline.open) / selectedKline.open * 100
    }

    private var displayColor: Color {
        guard let selectedKline = selectedKline else {
            return index.change >= 0 ? .red : .green
        }
        return selectedKline.close >= selectedKline.open ? .red : .green
    }

    private var periodPicker: some View {
        HStack(spacing: 8) {
            ForEach(KlinePeriod.allCases, id: \.self) { period in
                Button(action: {
                    selectedPeriod = period
                }) {
                    Text(period.title)
                        .font(.system(size: 14, weight: selectedPeriod == period ? .semibold : .regular))
                        .foregroundStyle(selectedPeriod == period ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedPeriod == period ? Color(red: 0.25, green: 0.25, blue: 0.28) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
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
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func loadKlines() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let tsCode = index.tsCode else {
            errorMessage = "缺少指数代码"
            return
        }

        do {
            klines = try await StockService.fetchKlines(code: tsCode, period: selectedPeriod, limit: 200)
        } catch APIError.unauthorized {
            errorMessage = "未登录，请先登录"
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
        }
    }
}

#Preview {
    HomeView()
}
