import SwiftUI

// MARK: - 启动屏

struct SplashView: View {
    let onComplete: (PreloadedHomeData?, String?) -> Void

    @State private var dailyQuote: DailyQuoteData?

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 16) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Text("盈多多")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(YPColor.brandGradient)
                }

                if let quote = dailyQuote {
                    VStack(spacing: 10) {
                        Text(quote.content)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 40)

                        if let author = quote.author, !author.isEmpty {
                            Text("—— \(author)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    VStack(spacing: 10) {
                        Text("投资是一场修行，耐心是最好的策略。")
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 40)

                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(YPColor.brandBlue)
                            .padding(.top, 8)
                    }
                    .transition(.opacity)
                }

                Spacer()

                Text("数据加载中…")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 24)
            }
        }
        .task {
            await bootstrap()
        }
    }

    // MARK: - 启动流程

    private func bootstrap() async {
        let start = Date()
        let autoLoginError = await ensureLogin()

        // 每日一言独立加载（不受超时影响）
        let quoteTask = Task { await loadDailyQuote() }

        // 首页数据加载（带超时）
        let homeTask = Task { await loadHomeData() }
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            homeTask.cancel()
        }

        // 等待每日一言（最多 2 秒）
        let quote: DailyQuoteData?
        let quoteTimeout = Task<DailyQuoteData?, Never> {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            return nil
        }
        quote = await withTaskGroup(of: DailyQuoteData?.self) { group in
            group.addTask { await quoteTask.value }
            group.addTask { await quoteTimeout.value }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }

        // 等待首页数据
        let homeData: PreloadedHomeData
        do {
            homeData = try await homeTask.value
        } catch {
            homeData = PreloadedHomeData(domesticIndices: [], globalIndices: [], watchlist: [], hotSectors: [], dailyQuote: nil)
            print("[Splash] 预加载超时或被取消")
        }
        timeoutTask.cancel()

        await MainActor.run {
            self.dailyQuote = quote
        }

        // 保证至少展示 1.2 秒
        let elapsed = Date().timeIntervalSince(start)
        let remaining = max(0, 1.2 - elapsed)
        if remaining > 0 {
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }

        let result = PreloadedHomeData(
            domesticIndices: homeData.domesticIndices,
            globalIndices: homeData.globalIndices,
            watchlist: homeData.watchlist,
            hotSectors: homeData.hotSectors,
            dailyQuote: quote
        )

        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                onComplete(result, autoLoginError)
            }
        }
    }

    private func ensureLogin() async -> String? {
        guard NetworkService.shared.getAuthToken() == nil else { return nil }
        // 5 秒超时，避免后端不可达时卡死启动页
        let loginTask = Task {
            try await AuthService.loginWithTestAccount()
        }
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 5_000_000_000)
            loginTask.cancel()
        }
        do {
            _ = try await loginTask.value
            timeoutTask.cancel()
            return nil
        } catch {
            timeoutTask.cancel()
            return "自动登录失败: \(error.localizedDescription)"
        }
    }

    private func loadDailyQuote() async -> DailyQuoteData? {
        do {
            return try await DailyQuoteService.fetchTodayQuote()
        } catch {
            print("[Splash] 每日一言加载失败: \(error)")
            return nil
        }
    }

    private func loadHomeData() async -> PreloadedHomeData {
        async let domesticTask = fetchCatching(
            try await StockService.fetchDomesticIndices(policy: .default),
            default: [],
            label: "国内指数"
        )
        async let globalTask = fetchCatching(
            try await StockService.fetchGlobalIndices(policy: .default),
            default: [],
            label: "全球指数"
        )
        async let watchlistTask = fetchCatching(
            try await StockService.fetchWatchlist(),
            default: [],
            label: "自选"
        )
        async let hotSectorsTask = fetchCatching(
            try await StockService.fetchSectorMoneyflow(sectorType: .industry, limit: 12, policy: .default).sectors,
            default: [],
            label: "热门板块"
        )

        let (domestic, global, watchlist, hotSectors) = await (domesticTask, globalTask, watchlistTask, hotSectorsTask)

        let coreGlobalCodes: Set<String> = ["DJI", "SPX", "IXIC", "HSI", "N225"]
        let filteredGlobal = global.filter { coreGlobalCodes.contains($0.tsCode ?? "") }

        return PreloadedHomeData(
            domesticIndices: domestic,
            globalIndices: filteredGlobal,
            watchlist: watchlist,
            hotSectors: hotSectors,
            dailyQuote: nil
        )
    }

    private func fetchCatching<T>(_ operation: @autoclosure () async throws -> T, default defaultValue: T, label: String) async -> T {
        do {
            return try await operation()
        } catch {
            if !(error is CancellationError) {
                print("[Splash] \(label) 预加载失败: \(error)")
            }
            return defaultValue
        }
    }
}

#Preview {
    SplashView { _, _ in }
}
