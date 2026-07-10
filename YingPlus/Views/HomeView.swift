import SwiftUI

struct HomeView: View {
    @State private var indices: [IndexItem] = []
    @State private var hsgtFlow: [HsgtFlowData] = []
    @State private var hotSectors: [SectorMoneyflowData] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
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
                await loadAllData()
            }
            .task {
                await loadAllData()
            }
        }
    }

    // MARK: - 数据加载

    private func loadAllData() async {
        isLoading = true
        defer { isLoading = false }

        async let indicesTask = StockService.fetchIndices()
        async let hsgtTask = MarketService.fetchHsgtFlow(limit: 5)
        async let sectorsTask = StockService.fetchSectorMoneyflow(sectorType: .industry, limit: 8)

        do { indices = try await indicesTask } catch { print("[Home] 指数加载失败: \(error)") }
        do { hsgtFlow = try await hsgtTask } catch { print("[Home] 北向资金加载失败: \(error)") }
        do {
            let resp = try await sectorsTask
            hotSectors = resp.sectors
        } catch { print("[Home] 板块加载失败: \(error)") }
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

    // MARK: - 市场概览（大盘指数）

    private var marketOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink {
                IndicesListView()
            } label: {
                SectionHeaderView(icon: "chart.bar", title: "市场概览", color: YPColor.accent, trailing: "查看全部")
            }
            .buttonStyle(.plain)

            if indices.isEmpty {
                // 骨架屏
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(0..<4) { _ in
                        skeletonCard
                    }
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(indices) { index in
                        indexCard(index)
                    }
                }
            }
        }
    }

    private func indexCard(_ item: IndexItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(String(format: "%.2f", item.value))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(item.change >= 0 ? YPColor.up : YPColor.down)
            Text(String(format: "%+.2f%%", item.change))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(item.change >= 0 ? YPColor.up : YPColor.down)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var skeletonCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 60, height: 12)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 90, height: 18)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 50, height: 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
                PlaceholderCard(icon: "arrow.up.arrow.down", description: "北向资金数据加载中...", color: YPColor.info)
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
                            SectorDetailView(sector: sector)
                        } label: {
                            sectorRow(index: index, sector: sector)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func sectorRow(index: Int, sector: SectorMoneyflowData) -> some View {
        HStack(spacing: 10) {
            Text("\(index + 1)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(index < 3 ? YPColor.warning : .secondary)
                .frame(width: 20)

            Text(sector.name ?? "--")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(1)

            if let lead = sector.leadStock {
                Text(lead)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            if let pct = sector.pctChange {
                Text(String(format: "%+.2f%%", pct))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(pct >= 0 ? YPColor.up : YPColor.down)
            }

            if let net = sector.netAmount {
                Text(String(format: "%.0f亿", net))
                    .font(.caption)
                    .foregroundStyle(net >= 0 ? YPColor.up : YPColor.down)
                    .frame(width: 50, alignment: .trailing)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.quaternary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    HomeView()
}
