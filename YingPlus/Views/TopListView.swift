import SwiftUI

// MARK: - 龙虎榜详情页

struct TopListView: View {
    @State private var topListItems: [TopListItem] = []
    @State private var isLoading = false
    @State private var loadError: Error?
    @State private var selectedDate: Date
    @State private var isDatePickerPresented = false

    init() {
        _selectedDate = State(initialValue: TopListView.latestTradeDate())
    }

    private static let requestFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let date = topListItems.first?.tradeDate {
                    tradeDateHeader(date)
                }

                if isLoading && topListItems.isEmpty {
                    loadingList
                } else if let error = loadError {
                    errorState(error)
                } else if topListItems.isEmpty {
                    PlaceholderCard(
                        icon: "trophy.circle",
                        title: "暂无数据",
                        description: "暂无龙虎榜数据",
                        color: YPColor.warning
                    )
                } else {
                    topListContent
                }
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("龙虎榜")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isDatePickerPresented = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(displayDate(selectedDate))
                            .font(.subheadline)
                    }
                    .foregroundStyle(YPColor.warning)
                }
            }
        }
        .refreshable { await loadData(forceRefresh: true) }
        .task { await loadData() }
        .sheet(isPresented: $isDatePickerPresented) {
            datePickerSheet
        }
    }

    private var topListContent: some View {
        LazyVStack(spacing: 10) {
            ForEach(topListItems) { item in
                NavigationLink {
                    StockDetailView(code: item.tsCode, name: item.name ?? item.tsCode)
                } label: {
                    topListCard(item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func topListCard(_ item: TopListItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name ?? item.tsCode)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(item.tsCode)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if let pct = item.pctChange {
                    Text(String(format: "%+.2f%%", pct))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(pct >= 0 ? YPColor.up : YPColor.down)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            HStack(spacing: 16) {
                metricItem(title: "净买入", value: item.netAmountFormatted, color: (item.netAmount ?? 0) >= 0 ? YPColor.up : YPColor.down)

                if let turnover = item.turnoverRate {
                    metricItem(title: "换手率", value: String(format: "%.2f%%", turnover))
                }

                if let amount = item.amount {
                    metricItem(title: "成交额", value: formatAmount(amount))
                }

                Spacer()
            }

            if let reason = item.reason, !reason.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb")
                        .font(.caption2)
                        .foregroundStyle(YPColor.warning)
                    Text(reason)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func metricItem(title: String, value: String, color: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color ?? .primary)
        }
    }

    private func formatAmount(_ amount: Double) -> String {
        if abs(amount) >= 100_000_000 {
            return String(format: "%.2f亿", amount / 100_000_000)
        } else if abs(amount) >= 10_000 {
            return String(format: "%.0f万", amount / 10_000)
        }
        return String(format: "%.0f", amount)
    }

    private var loadingList: some View {
        VStack(spacing: 10) {
            ForEach(0..<6) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 100)
            }
        }
    }

    private func errorState(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(YPColor.warning.opacity(0.8))
            Text("数据加载失败")
                .font(.subheadline)
                .fontWeight(.medium)
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func tradeDateHeader(_ date: String) -> some View {
        HStack {
            Spacer()
            Image(systemName: "calendar")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formatTradeDate(date))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var datePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker(
                    "选择交易日",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()

                Spacer()
            }
            .navigationTitle("选择交易日")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("确定") {
                        isDatePickerPresented = false
                        Task { await loadData(forceRefresh: true) }
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        isDatePickerPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func loadData(forceRefresh: Bool = false) async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        let policy: CachePolicy = forceRefresh ? .skipCache : .default
        let calendar = Calendar.current
        var date = selectedDate

        // 最多回退 5 个交易日请求数据
        for _ in 0..<5 {
            let dateString = Self.requestFormatter.string(from: date)
            do {
                topListItems = try await MarketService.fetchTopList(tradeDate: dateString, limit: 50, policy: policy)
                if !topListItems.isEmpty {
                    selectedDate = date
                    return
                }
            } catch {
                if error is CancellationError { return }
                print("[TopList] \(dateString) 加载失败: \(error.localizedDescription)")
                loadError = error
            }
            date = previousTradeDate(from: date, calendar: calendar)
        }
    }

    private func previousTradeDate(from date: Date, calendar: Calendar) -> Date {
        var previous = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        while Self.isWeekend(previous, calendar: calendar) {
            previous = calendar.date(byAdding: .day, value: -1, to: previous) ?? previous
        }
        return previous
    }

    private func formatTradeDate(_ date: String) -> String {
        guard date.count == 8 else { return date }
        let year = date.prefix(4)
        let month = date[date.index(date.startIndex, offsetBy: 4)..<date.index(date.startIndex, offsetBy: 6)]
        let day = date[date.index(date.startIndex, offsetBy: 6)...]
        return "\(year)-\(month)-\(day)"
    }

    private func displayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter.string(from: date)
    }

    private static func latestTradeDate() -> Date {
        let calendar = Calendar.current
        var date = Date()
        while isWeekend(date, calendar: calendar) {
            date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        }
        return date
    }

    private static func isWeekend(_ date: Date, calendar: Calendar) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }
}

#Preview {
    NavigationStack {
        TopListView()
    }
}
