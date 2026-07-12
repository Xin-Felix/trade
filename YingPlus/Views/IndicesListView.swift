import SwiftUI

/// 大盘指数列表页 — 展示国内及全球主要指数
struct IndicesListView: View {
    @State private var domesticIndices: [IndexItem] = []
    @State private var globalIndices: [IndexItem] = []
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading && domesticIndices.isEmpty && globalIndices.isEmpty {
                    skeletonGrid
                } else {
                    if !domesticIndices.isEmpty {
                        section(title: "国内大盘", indices: domesticIndices)
                    }

                    if !globalIndices.isEmpty {
                        section(title: "全球大盘", indices: globalIndices)
                    }

                    if domesticIndices.isEmpty && globalIndices.isEmpty && !isLoading {
                        Text("暂无指数数据")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("大盘指数")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await loadData(forceRefresh: true) }
        .task { await loadData() }
    }

    private func section(title: String, indices: [IndexItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                spacing: 12
            ) {
                ForEach(indices) { index in
                    NavigationLink {
                        if let code = index.tsCode {
                            IndexDetailView(code: code, name: index.name)
                        }
                    } label: {
                        indexCard(index)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func loadData(forceRefresh: Bool = false) async {
        isLoading = true
        defer { isLoading = false }

        let policy: CachePolicy = forceRefresh ? .skipCache : .default

        async let domesticTask = StockService.fetchDomesticIndices(policy: policy)
        async let globalTask = StockService.fetchGlobalIndices(policy: policy)

        do { domesticIndices = try await domesticTask } catch {
            if error is CancellationError { return }
            print("[IndicesList] 国内指数加载失败: \(error)")
        }
        do { globalIndices = try await globalTask } catch {
            if error is CancellationError { return }
            print("[IndicesList] 全球指数加载失败: \(error)")
        }
    }

    private func indexCard(_ item: IndexItem) -> some View {
        let trendColor = item.change >= 0 ? YPColor.up : YPColor.down

        return VStack(spacing: 8) {
            // 名称与代码
            VStack(spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let code = item.tsCode {
                    Text(code)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            // 点位
            Text(String(format: "%.2f", item.value))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(trendColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // 涨跌幅标签
            Text(String(format: "%+.2f%%", item.change))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .frame(maxWidth: .infinity)
                .background(trendColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .frame(height: 110)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var skeletonGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
            spacing: 12
        ) {
            ForEach(0..<6) { _ in
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 70, height: 14)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 40, height: 10)

                    Spacer(minLength: 0)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 80, height: 22)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 20)
                }
                .frame(height: 110)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

/// 单个指数详情页 — K线走势
struct IndexDetailView: View {
    let code: String
    let name: String

    @State private var dailyData: [IndexDailyData] = []
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let latest = dailyData.first {
                    // 最新数据卡片
                    VStack(spacing: 8) {
                        Text(String(format: "%.2f", latest.close))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(latest.pctChg >= 0 ? YPColor.up : YPColor.down)

                        HStack(spacing: 16) {
                            Label(String(format: "%+.2f", latest.change), systemImage: "arrow.up.arrow.down")
                            Label(String(format: "%+.2f%%", latest.pctChg), systemImage: "percent")
                        }
                        .font(.subheadline)
                        .foregroundStyle(latest.pctChg >= 0 ? YPColor.up : YPColor.down)

                        Text(formatTradeDate(latest.tradeDate))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // 成交额
                    HStack(spacing: 12) {
                        infoCell(title: "成交额", value: latest.amountFormatted)
                        infoCell(title: "最高", value: String(format: "%.2f", latest.high))
                        infoCell(title: "最低", value: String(format: "%.2f", latest.low))
                    }
                }

                // 近期走势列表
                VStack(alignment: .leading, spacing: 8) {
                    Text("近期走势")
                        .font(.headline)
                        .padding(.top, 8)

                    ForEach(dailyData.prefix(20)) { item in
                        HStack {
                            Text(formatTradeDate(item.tradeDate))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 75, alignment: .leading)

                            Spacer()

                            Text(String(format: "%.2f", item.close))
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text(String(format: "%+.2f%%", item.pctChg))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(item.pctChg >= 0 ? YPColor.up : YPColor.down)
                                .frame(width: 65, alignment: .trailing)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadData() }
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            dailyData = try await MarketService.fetchIndexDaily(code: code, limit: 30)
        } catch {
            if error is CancellationError { return }
            print("[IndexDetail] 加载失败: \(error)")
        }
    }

    private func infoCell(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func formatTradeDate(_ date: String) -> String {
        // "20260710" -> "07-10"
        guard date.count == 8 else { return date }
        let month = date[date.index(date.startIndex, offsetBy: 4)..<date.index(date.startIndex, offsetBy: 6)]
        let day = date[date.index(date.startIndex, offsetBy: 6)...]
        return "\(month)-\(day)"
    }
}

#Preview {
    NavigationStack {
        IndicesListView()
    }
}
