import SwiftUI

/// 大盘指数列表页 — 展示所有主要指数及近期走势
struct IndicesListView: View {
    @State private var indices: [IndexItem] = []
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if isLoading && indices.isEmpty {
                    ForEach(0..<6) { _ in
                        skeletonRow
                    }
                } else {
                    ForEach(indices) { index in
                        NavigationLink {
                            if let code = index.tsCode {
                                IndexDetailView(code: code, name: index.name)
                            }
                        } label: {
                            indexRow(index)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("大盘指数")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await loadData() }
        .task { await loadData() }
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            indices = try await StockService.fetchIndices()
        } catch {
            print("[IndicesList] 加载失败: \(error)")
        }
    }

    private func indexRow(_ item: IndexItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                if let code = item.tsCode {
                    Text(code)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f", item.value))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(item.change >= 0 ? YPColor.up : YPColor.down)
                Text(String(format: "%+.2f%%", item.change))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(item.change >= 0 ? YPColor.up : YPColor.down)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.quaternary)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var skeletonRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 80, height: 14)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 60, height: 10)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 70, height: 16)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
