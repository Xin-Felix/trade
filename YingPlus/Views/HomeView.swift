import SwiftUI

struct HomeView: View {
    let preloadedData: PreloadedHomeData?

    @State private var domesticIndices: [IndexItem] = []
    @State private var globalIndices: [IndexItem] = []
    @State private var hotSectors: [SectorMoneyflowData] = []
    @State private var marketSentiment: MarketSentiment? = nil
    @State private var aiMorningBrief: String? = nil
    @State private var aiMorningBriefDate: String? = nil
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    marketSentimentSection
                    aiMorningBriefSection
                    marketOverviewSection
                    hotSectorsSection
                }
                .padding()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("盈多多")
            .refreshable {
                await loadAllData(forceRefresh: true)
            }
            .task {
                if let preloaded = preloadedData {
                    applyPreloadedData(preloaded)
                    await loadMorningReport()
                } else {
                    await loadAllData()
                }
            }
        }
    }

    // MARK: - 数据加载

    private func applyPreloadedData(_ data: PreloadedHomeData) {
        domesticIndices = data.domesticIndices
        globalIndices = data.globalIndices
        hotSectors = data.hotSectors

        // 市场温度从 API 拉取，预加载阶段先用 nil
        marketSentiment = nil
        aiMorningBrief = nil
    }

    private func loadAllData(forceRefresh: Bool = false) async {
        isLoading = true
        defer { isLoading = false }

        let policy: CachePolicy = forceRefresh ? .skipCache : .default

        async let domesticTask = StockService.fetchDomesticIndices(policy: policy)
        async let globalTask = StockService.fetchGlobalIndices(policy: policy)
        async let hotSectorsTask = StockService.fetchSectorMoneyflow(sectorType: .industry, limit: 12, policy: policy)
        async let morningReportTask = AiMorningReportService.fetchLatestAvailableReport()
        async let pulseTask = MarketPulseService.fetchToday()

        do { domesticIndices = try await domesticTask } catch { if error is CancellationError { return }; print("[Home] 国内指数加载失败: \(error)") }
        do {
            let global = try await globalTask
            let coreGlobalCodes: Set<String> = ["DJI", "SPX", "IXIC", "HSI", "N225"]
            globalIndices = global.filter { coreGlobalCodes.contains($0.tsCode ?? "") }
        } catch { if error is CancellationError { return }; print("[Home] 全球指数加载失败: \(error)") }
        do {
            let resp = try await hotSectorsTask
            hotSectors = resp.sectors
        } catch { if error is CancellationError { return }; print("[Home] 热门板块加载失败: \(error)") }

        // 市场温度 - 从 API 获取
        do {
            if let pulse = try await pulseTask {
                let indicators = MarketPulseIndicatorDisplay(
                    upCount: pulse.indicators.upCount ?? 0,
                    downCount: pulse.indicators.downCount ?? 0,
                    amount: pulse.indicators.amount ?? 0,
                    amountChangePct: pulse.indicators.amountChangePct ?? 0,
                    northMoney: pulse.indicators.northMoney ?? 0,
                    limitUpCount: pulse.indicators.limitUpCount ?? 0,
                    limitDownCount: pulse.indicators.limitDownCount ?? 0,
                    maxBoard: pulse.indicators.maxContinuousBoard ?? 0
                )
                marketSentiment = MarketSentiment(
                    score: pulse.score,
                    label: pulse.level,
                    reason: pulse.summary ?? "",
                    keywords: pulse.keywords,
                    indicators: indicators,
                    tradeDate: pulse.tradeDate
                )
            } else {
                // API 无数据时降级为本地简单计算
                let score = deriveSentimentScore(from: domesticIndices)
                marketSentiment = MarketSentiment(
                    score: score,
                    label: sentimentLabel(for: score),
                    reason: "",
                    keywords: [],
                    indicators: nil,
                    tradeDate: nil
                )
            }
        } catch {
            if error is CancellationError { return }
            print("[Home] 市场温度加载失败: \(error)")
            let score = deriveSentimentScore(from: domesticIndices)
            marketSentiment = MarketSentiment(
                score: score,
                label: sentimentLabel(for: score),
                reason: "",
                keywords: [],
                indicators: nil,
                tradeDate: nil
            )
        }

        do {
            let report = try await morningReportTask
            await applyMorningReport(report)
        } catch {
            if error is CancellationError { return }
            print("[Home] AI 晨报加载失败: \(error)")
            aiMorningBrief = nil
            aiMorningBriefDate = nil
        }
    }

    private func loadMorningReport() async {
        do {
            let report = try await AiMorningReportService.fetchLatestAvailableReport()
            await applyMorningReport(report)
        } catch {
            if error is CancellationError { return }
            print("[Home] AI 晨报加载失败: \(error)")
            aiMorningBrief = nil
            aiMorningBriefDate = nil
        }
    }

    @MainActor
    private func applyMorningReport(_ report: AiMorningReportItem) {
        if report.status == "success" {
            aiMorningBrief = report.summary ?? report.content
            aiMorningBriefDate = report.reportDate
        } else {
            aiMorningBrief = nil
            aiMorningBriefDate = nil
        }
    }

    private func deriveSentimentScore(from indices: [IndexItem]) -> Int {
        guard !indices.isEmpty else { return 50 }
        let rising = indices.filter { $0.change >= 0 }.count
        let ratio = Double(rising) / Double(indices.count)
        return Int((ratio * 100).rounded())
    }

    private func sentimentLabel(for score: Int) -> String {
        switch score {
        case 0..<30: return "悲观"
        case 30..<50: return "谨慎"
        case 50..<70: return "中性偏多"
        default: return "乐观"
        }
    }

    // MARK: - 市场情绪

    private var marketSentimentSection: some View {
        MarketSentimentCard(sentiment: marketSentiment)
    }

    // MARK: - AI 晨报

    private var aiMorningBriefSection: some View {
        NavigationLink {
            MorningReportView()
        } label: {
            AIMorningBriefCard(summary: aiMorningBrief, reportDate: aiMorningBriefDate)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 市场概览

    private var marketOverviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView(icon: "chart.bar", title: "市场概览", color: YPColor.market)

            NavigationLink {
                IndicesListView()
            } label: {
                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.caption2)
                            .foregroundStyle(YPColor.market)
                        Text("全球股市")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(YPColor.market)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(YPColor.market)
                    }
                    .frame(height: 24, alignment: .center)

                    if domesticIndices.isEmpty && globalIndices.isEmpty {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.tertiarySystemFill))
                            .frame(height: 14)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity, alignment: .center)
                    } else {
                        let indices = globalIndices + domesticIndices
                        IndexMarqueeView(indices: indices)
                            .frame(height: 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .clipped()
                    }
                }
                .frame(height: 34)
                .padding(.horizontal, 12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 热门板块

    private var hotSectorsSection: some View {
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
}

#Preview {
    HomeView(preloadedData: nil)
}
