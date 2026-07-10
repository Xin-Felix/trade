import SwiftUI

struct StockDetailView: View {
    let code: String
    let name: String

    @State private var selectedPeriod: KlinePeriod = .intraday
    @State private var klines: [KlineData] = []
    @State private var selectedKline: KlineData?
    @State private var quote: StockData?
    @State private var dailyBasic: DailyBasicData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var refreshTimer: Timer?

    // MARK: - V1.0 规划模块
    // 1. ✅ AI 总结（待接入）
    // 2. ✅ K线/分时
    // 3. 🔲 主力资金
    // 4. 🔲 大小单/内外盘
    // 5. 🔲 所属板块
    // 6. 🔲 新闻
    // 7. 🔲 公告
    // 8. ✅ 财务（指标）
    // 9. 🔲 龙虎榜

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    headerView
                    periodPicker
                    chartSection
                    indicatorsSection
                    // TODO: 主力资金 section
                    // TODO: 大小单/内外盘 section
                    // TODO: 所属板块 section
                    // TODO: 新闻 section
                    // TODO: 公告 section
                    // TODO: 龙虎榜 section
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text(code)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Spacer()

                if let selectedKline = selectedKline {
                    Text(selectedKline.tradeDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if selectedPeriod.isIntraday, let last = klines.first {
                    Text(last.tradeDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

            let price = displayPrice
            let changePercent = selectedKlineChangePercent

            if let price = price {
                HStack(alignment: .lastTextBaseline, spacing: 12) {
                    Text(String(format: "%.2f", price))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(displayColor)

                    if let changePercent = changePercent {
                        Text(String(format: "%.2f%%", changePercent))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(displayColor)
                    }
                }
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 12) {
                    skeletonBar(width: 120, height: 36)
                    skeletonBar(width: 80, height: 24)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }

    private var isInWatchlist: Bool {
        WatchlistService.contains(code: code)
    }

    private func toggleWatchlist() {
        if isInWatchlist {
            WatchlistService.remove(code: code)
        } else {
            WatchlistService.add(code: code, name: name)
        }
    }

    private var selectedKlineChangePercent: Double? {
        if let selectedKline = selectedKline {
            // 长按选中：用昨收价计算涨跌幅
            if let preClose = quote?.preClose, preClose != 0 {
                return (selectedKline.close - preClose) / preClose * 100
            }
            guard selectedKline.open != 0 else { return 0 }
            return (selectedKline.close - selectedKline.open) / selectedKline.open * 100
        }

        // 分时模式：最新价 vs 昨日收盘价
        if selectedPeriod.isIntraday, let preClose = quote?.preClose, preClose != 0,
           let latestClose = klines.first?.close {
            return (latestClose - preClose) / preClose * 100
        }

        return quote?.changePercent
    }

    private var displayPrice: Double? {
        if let selectedKline = selectedKline {
            return selectedKline.close
        }
        // 分时模式：显示最新价（后端降序，first=最新）
        if selectedPeriod.isIntraday, let latestClose = klines.first?.close {
            return latestClose
        }
        return quote?.price
    }

    private var displayColor: Color {
        let change = selectedKlineChangePercent ?? 0
        return change >= 0 ? .red : .green
    }

    // MARK: - Period Picker

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
    }

    // MARK: - Chart Section

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
        .padding()
    }

    // MARK: - Indicators Section

    private var indicatorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("股票指标")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let dailyBasic = dailyBasic {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    indicatorItem("市盈率 PE", value: dailyBasic.pe, suffix: nil)
                    indicatorItem("PE TTM", value: dailyBasic.peTtm, suffix: nil)
                    indicatorItem("市净率 PB", value: dailyBasic.pb, suffix: nil)
                    indicatorItem("市销率 PS", value: dailyBasic.ps, suffix: nil)
                    indicatorItem("换手率", value: dailyBasic.turnoverRate, suffix: "%")
                    indicatorItem("量比", value: dailyBasic.volumeRatio, suffix: nil)
                    indicatorItem("总市值", value: dailyBasic.totalMv, suffix: nil, isVolume: true)
                    indicatorItem("流通市值", value: dailyBasic.circMv, suffix: nil, isVolume: true)
                    indicatorItem("股息率", value: dailyBasic.dvTtm, suffix: "%")
                }
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.bottom, 16)
    }

    private func indicatorItem(_ title: String, value: Double?, suffix: String?, isVolume: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let value = value {
                Text(isVolume ? formatBigNumber(value) : formatIndicator(value, suffix: suffix))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
            } else {
                Text("-")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
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
        guard selectedPeriod.isIntraday else { return }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                await loadKlines()
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
        async let klinesTask: () = loadKlines()
        async let indicatorsTask: () = loadIndicators()
        _ = await (quoteTask, klinesTask, indicatorsTask)
    }

    private func loadQuote() async {
        do {
            quote = try await StockService.fetchQuote(code: code)
        } catch {
            print("加载行情失败: \(error.localizedDescription)")
        }
    }

    private func loadKlines() async {
        errorMessage = nil

        // 分时 K 线不缓存，直接从服务端拉取
        if selectedPeriod.isIntraday {
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
            case .intraday: return 240
            case .day: return 60
            case .week: return 20
            case .month: return 12
            case .year: return 5
            }
        } else {
            switch period {
            case .intraday: return 240
            case .day: return 500
            case .week: return 200
            case .month: return 120
            case .year: return 30
            }
        }
    }

    private func loadIndicators() async {
        do {
            let data = try await StockService.fetchDailyBasic(code: code, limit: 1)
            dailyBasic = data.first
        } catch {
            print("加载指标失败: \(error.localizedDescription)")
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
