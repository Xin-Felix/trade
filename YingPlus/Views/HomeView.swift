import SwiftUI

struct HomeView: View {
    @State private var domesticIndices: [IndexItem] = []
    @State private var globalIndices: [IndexItem] = []
    @State private var hsgtFlow: [HsgtFlowData] = []
    @State private var hotSectors: [SectorMoneyflowData] = []
    @State private var dailyQuote: DailyQuoteData?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if dailyQuote != nil {
                        dailyQuoteSection
                    }
                    aiMorningBriefSection
                    marketOverviewSection
                    northFlowSection
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
                await loadAllData()
            }
        }
    }

    // MARK: - 数据加载

    private func loadAllData(forceRefresh: Bool = false) async {
        isLoading = true
        defer { isLoading = false }

        let policy: CachePolicy = forceRefresh ? .skipCache : .default

        async let domesticTask = StockService.fetchDomesticIndices(policy: policy)
        async let globalTask = StockService.fetchGlobalIndices(policy: policy)
        async let hsgtTask = MarketService.fetchHsgtFlow(limit: 5, policy: policy)
        async let sectorsTask = StockService.fetchSectorMoneyflow(sectorType: .industry, limit: 8, policy: policy)
        async let quoteTask = DailyQuoteService.fetchTodayQuote(policy: policy)

        do { domesticIndices = try await domesticTask } catch { if error is CancellationError { return }; print("[Home] 国内指数加载失败: \(error)") }
        do {
            let global = try await globalTask
            let coreGlobalCodes: Set<String> = ["DJI", "SPX", "IXIC", "HSI", "N225"]
            globalIndices = global.filter { coreGlobalCodes.contains($0.tsCode ?? "") }
        } catch { if error is CancellationError { return }; print("[Home] 全球指数加载失败: \(error)") }
        do { hsgtFlow = try await hsgtTask } catch { if error is CancellationError { return }; print("[Home] 北向资金加载失败: \(error)") }
        do {
            let resp = try await sectorsTask
            hotSectors = resp.sectors
        } catch { if error is CancellationError { return }; print("[Home] 板块加载失败: \(error)") }
        do { dailyQuote = try await quoteTask } catch { if error is CancellationError { return }; print("[Home] 每日一言加载失败: \(error)") }
    }

    // MARK: - AI 晨报

    private var aiMorningBriefSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "brain", title: "AI 晨报", color: YPColor.ai, trailing: "今日")

            VStack(alignment: .leading, spacing: 0) {
                briefItem(icon: "doc.text", title: "市场总结", description: "AI 自动生成今日市场概况")
                Divider().padding(.leading, 40)
                briefItem(icon: "chart.pie", title: "建议仓位", description: "基于市场情绪的仓位建议")
                Divider().padding(.leading, 40)
                briefItem(icon: "flame", title: "热点板块", description: "今日资金流入最多的板块")
                Divider().padding(.leading, 40)
                briefItem(icon: "exclamationmark.triangle", title: "风险提示", description: "需要关注的风险因素")
                Divider().padding(.leading, 40)
                briefItem(icon: "globe", title: "国际市场", description: "隔夜外盘走势总结")
            }
            .padding(.vertical, 4)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func briefItem(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(YPColor.ai)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - 每日一言

    private var dailyQuoteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "quote.bubble", title: "每日一言", color: YPColor.info)

            if let quote = dailyQuote {
                VStack(alignment: .leading, spacing: 10) {
                    Text("“\(quote.content)”")
                        .font(.body)
                        .lineSpacing(4)

                    if let author = quote.author, !author.isEmpty {
                        HStack {
                            Spacer()
                            Text("—— \(author)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - 市场概览（单行指数跑马灯）

    private var marketOverviewSection: some View {
        NavigationLink {
            IndicesListView()
        } label: {
            HStack(spacing: 10) {
                // 左侧固定标签
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                        .font(.caption2)
                        .foregroundStyle(YPColor.accent)
                    Text("全球股市")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(YPColor.accent)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(YPColor.accent)
                }

                if domesticIndices.isEmpty && globalIndices.isEmpty {
                    // 骨架屏
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 14)
                        .frame(maxWidth: .infinity)
                } else {
                    let indices = globalIndices + domesticIndices
                    IndexMarqueeView(indices: indices)
                        .frame(height: 24)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 北向资金

    private var northFlowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "arrow.up.arrow.down.circle", title: "北向资金", color: YPColor.info)

            if let today = hsgtFlow.first {
                let yesterday = hsgtFlow.count > 1 ? hsgtFlow[1] : nil
                let todayNet = today.northMoney ?? 0
                let yesterdayNet = yesterday?.northMoney ?? 0
                let dailyChange = todayNet - yesterdayNet

                HStack(spacing: 12) {
                    // 今日净流入
                    VStack(alignment: .leading, spacing: 4) {
                        Text("今日合计")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(today.northMoneyFormatted)
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // 日变化
                    VStack(alignment: .leading, spacing: 4) {
                        Text("日变化")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%+.1f亿", dailyChange / 10000.0))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(dailyChange >= 0 ? YPColor.up : YPColor.down)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // 沪股通 / 深股通 明细
                HStack(spacing: 12) {
                    flowDetailItem(title: "沪股通", value: today.hgt)
                    flowDetailItem(title: "深股通", value: today.sgt)
                }
            } else {
                PlaceholderCard(
                    icon: "arrow.up.arrow.down",
                    title: "暂无数据",
                    description: "北向资金数据暂时为空",
                    color: YPColor.info
                )
            }
        }
    }

    private func flowDetailItem(title: String, value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let v = value {
                Text(String(format: "%.1f亿", v / 10000.0))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            } else {
                Text("--")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - 热点板块

    private var hotSectorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink {
                AllSectorsView()
            } label: {
                SectionHeaderView(icon: "flame", title: "热点板块", color: YPColor.warning, trailing: "查看全部")
            }
            .buttonStyle(.plain)

            if hotSectors.isEmpty {
                VStack(spacing: 6) {
                    ForEach(0..<5) { _ in
                        HStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(.tertiarySystemFill))
                                .frame(width: 60, height: 14)
                            Spacer()
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(.tertiarySystemFill))
                                .frame(width: 50, height: 14)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(hotSectors.prefix(8).enumerated()), id: \.element.id) { index, sector in
                        NavigationLink {
                            SectorDetailView(sector: sector, isConcept: false)
                        } label: {
                            SectorRow(
                                index: index,
                                name: sector.name,
                                leadStock: sector.leadStock,
                                pctChange: sector.pctChange,
                                netAmount: sector.netAmount
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
