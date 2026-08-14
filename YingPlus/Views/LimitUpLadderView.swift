import SwiftUI

/// 涨停梯队页
struct LimitUpLadderView: View {
    @State private var response: LimitUpLadderResponse?
    @State private var isLoading = false
    @State private var loadError: Error?
    @State private var selectedStock: LimitUpLadderStock?
    @State private var selectedConcept: LimitUpConceptTag?
    @State private var selectedDate: Date
    @State private var pickerDate: Date = Date()
    @State private var isDatePickerPresented = false
    @State private var conceptNameToId: [String: String] = [:]
    @State private var hasManualDateSelection = false

    init() {
        _selectedDate = State(initialValue: MarketCalendar.latestTradeDate())
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
                if let date = response?.tradeDate {
                    tradeDateHeader(date)
                }

                if isLoading && response == nil {
                    loadingList
                } else if let error = loadError {
                    errorState(error)
                } else if response?.ladder.isEmpty != false {
                    emptyState
                } else {
                    conceptTagsSection
                    ladderList
                }
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("涨停梯队")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        shareImage()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(YPColor.up)
                    }
                    .disabled(response?.ladder.isEmpty != false)

                    Button {
                        pickerDate = selectedDate
                        isDatePickerPresented = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(displayDate(selectedDate))
                                .font(.subheadline)
                        }
                        .foregroundStyle(YPColor.up)
                    }
                }
            }
        }
        .refreshable {
            if hasManualDateSelection {
                await loadData(for: selectedDate, forceRefresh: true)
            } else {
                await loadData(forceRefresh: true)
            }
        }
        .task { await loadData() }
        .sheet(isPresented: $isDatePickerPresented) {
            datePickerSheet
        }
        .navigationDestination(item: $selectedStock) { stock in
            StockDetailView(code: stock.tsCode, name: stock.name)
        }
        .navigationDestination(item: $selectedConcept) { concept in
            SectorDetailView(
                sector: SectorMoneyflowData(
                    tsCode: concept.id,
                    tradeDate: response?.tradeDate ?? "",
                    name: concept.name,
                    leadStock: nil,
                    closePrice: nil,
                    pctChange: concept.pctChange,
                    companyNum: concept.consCount,
                    pctChangeStock: nil,
                    netBuyAmount: nil,
                    netSellAmount: nil,
                    netAmount: nil
                ),
                isConcept: true
            )
        }
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
                    "选择日期",
                    selection: $pickerDate,
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
                        hasManualDateSelection = true
                        Task { await loadData(for: pickerDate, forceRefresh: true) }
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

    private var conceptTagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("涨停概念")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Text("TOP10")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            FlowLayout(spacing: 8) {
                ForEach(response?.conceptTags.prefix(15) ?? []) { tag in
                    conceptTagChip(tag)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func conceptTagChip(_ tag: LimitUpConceptTag) -> some View {
        Button {
            Task { await openConcept(tag) }
        } label: {
            HStack(spacing: 4) {
                Text(tag.name)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(tag.count)")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Self.tagColor(tag.name).opacity(0.12))
            .foregroundStyle(Self.tagColor(tag.name).opacity(0.9))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func openConcept(_ tag: LimitUpConceptTag) async {
        // 后端可能没有返回 concept_id，此时 id 是自动生成的 UUID，需要按名称匹配真实 code
        let isRealCode = tag.id.range(of: #"^\d+\.TI$"#, options: .regularExpression) != nil
        let conceptId = isRealCode ? tag.id : conceptNameToId[tag.name]
        guard let conceptId, !conceptId.isEmpty else { return }
        selectedConcept = LimitUpConceptTag(
            id: conceptId,
            name: tag.name,
            count: tag.count,
            consCount: tag.consCount,
            pctChange: tag.pctChange,
            rank: tag.rank
        )
    }

    private var ladderList: some View {
        VStack(spacing: 16) {
            ForEach(sortedLadder) { group in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(group.label)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(YPColor.up)
                        Spacer()
                        Text("\(group.stocks.count)只")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 10
                    ) {
                        ForEach(group.stocks) { stock in
                            Button {
                                selectedStock = stock
                            } label: {
                                stockCard(stock)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var sortedLadder: [LimitUpLadderGroup] {
        response?.ladder.sorted { $0.step > $1.step } ?? []
    }

    private var loadingList: some View {
        VStack(spacing: 14) {
            ForEach(0..<4) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 120)
            }
        }
    }

    private func stockCard(_ stock: LimitUpLadderStock) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(stock.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                Text(String(format: "%+.2f%%", stock.pctChg))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(YPColor.up)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            if let first = stock.firstTime, !first.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("首封 \(first)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if let tags = stock.conceptTags, !tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Self.tagColor(tag).opacity(0.12))
                            .foregroundStyle(Self.tagColor(tag))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.up.circle")
                .font(.title2)
                .foregroundStyle(YPColor.up.opacity(0.6))
            Text("暂无涨停梯队数据")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            Text("近期可能无涨停股票，或后端接口尚未返回数据")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func errorState(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(YPColor.warning.opacity(0.8))
            Text("数据加载失败")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

    /// 根据概念名称生成固定颜色
    fileprivate static func tagColor(_ name: String) -> Color {
        let colors: [Color] = [
            Color(red: 0.95, green: 0.25, blue: 0.25), // 红
            Color(red: 0.95, green: 0.55, blue: 0.10), // 橙
            Color(red: 0.10, green: 0.60, blue: 0.90), // 蓝
            Color(red: 0.45, green: 0.75, blue: 0.25), // 绿
            Color(red: 0.75, green: 0.30, blue: 0.85), // 紫
            Color(red: 0.95, green: 0.35, blue: 0.55), // 粉
            Color(red: 0.20, green: 0.75, blue: 0.75), // 青
            Color(red: 0.55, green: 0.40, blue: 0.25)  // 棕
        ]
        var hash = 0
        for char in name.unicodeScalars {
            hash = Int(char.value) + ((hash << 5) - hash)
        }
        return colors[abs(hash) % colors.count]
    }

    private func shareImage() {
        guard let response = response else { return }

        let exportView = LadderExportView(response: response)
            .environment(\.colorScheme, .light)

        guard let image = ShareService.renderImage(content: exportView, width: 390) else { return }
        ShareService.shareImage(image)
    }

    private func loadData(forceRefresh: Bool = false) async {
        await loadLatestData(forceRefresh: forceRefresh)
    }

    private func loadData(for date: Date, forceRefresh: Bool = false) async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        let dateString = Self.requestFormatter.string(from: date)
        do {
            let policy: CachePolicy = forceRefresh ? .skipCache : .default
            response = try await MarketService.fetchLimitUpLadder(tradeDate: dateString, policy: policy)
            selectedDate = date
            await loadConceptIdMapIfNeeded()
        } catch {
            if error is CancellationError { return }
            loadError = error
            print("[LimitUpLadder] \(dateString) 加载失败: \(error.localizedDescription)")
        }
    }

    private func loadLatestData(forceRefresh: Bool = false) async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        var date = MarketCalendar.latestTradeDate()
        var lastError: Error?
        var lastEmptyResponse: (response: LimitUpLadderResponse, date: Date)?

        // 最多回退 3 个交易日查找有数据的日期
        for _ in 0..<3 {
            // 用户已手动选择日期时，停止自动查找，避免覆盖用户选择
            guard !hasManualDateSelection else { return }

            let currentDate = date
            let dateString = Self.requestFormatter.string(from: currentDate)
            do {
                let policy: CachePolicy = forceRefresh ? .skipCache : .default
                let resp = try await MarketService.fetchLimitUpLadder(tradeDate: dateString, policy: policy)
                if !resp.ladder.isEmpty {
                    response = resp
                    selectedDate = currentDate
                    await loadConceptIdMapIfNeeded()
                    return
                }
                if lastEmptyResponse == nil {
                    lastEmptyResponse = (resp, currentDate)
                }
            } catch {
                if error is CancellationError { return }
                lastError = error
                print("[LimitUpLadder] \(dateString) 加载失败: \(error.localizedDescription)")
            }
            date = previousTradeDate(from: currentDate)
        }

        // 用户已手动选择日期时，不再用空响应兜底
        guard !hasManualDateSelection else { return }

        if let empty = lastEmptyResponse {
            response = empty.response
            selectedDate = empty.date
            await loadConceptIdMapIfNeeded()
        } else if let lastError = lastError {
            loadError = lastError
        }
    }

    private func loadConceptIdMapIfNeeded() async {
        guard conceptNameToId.isEmpty,
              response?.conceptTags.contains(where: { $0.id.isEmpty }) == true else { return }

        do {
            let list = try await ConceptFlowService.fetchAvailableConcepts()
            var map: [String: String] = [:]
            for concept in list.data.concepts {
                map[concept.concept_name] = concept.concept_id
            }
            conceptNameToId = map
        } catch {
            print("[LimitUpLadder] 概念列表加载失败: \(error.localizedDescription)")
        }
    }

    private func previousTradeDate(from date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = MarketCalendar.timeZone
        var previous = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        while !MarketCalendar.isTradeDay(previous) {
            previous = calendar.date(byAdding: .day, value: -1, to: previous) ?? previous
        }
        return previous
    }
}

// MARK: - 流式布局

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    private struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

private struct LadderExportView: View {
    let response: LimitUpLadderResponse

    private var sortedLadder: [LimitUpLadderGroup] {
        response.ladder.sorted { $0.step > $1.step }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("涨停梯队")
                .font(.title2)
                .fontWeight(.bold)

            Text(formatTradeDate(response.tradeDate))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            conceptTagsSection

            ForEach(sortedLadder) { group in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(group.label)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(YPColor.up)
                        Spacer()
                        Text("\(group.stocks.count)只")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 10
                    ) {
                        ForEach(group.stocks) { stock in
                            exportStockCard(stock)
                        }
                    }
                }
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .frame(width: 390)
        .background(Color(.systemBackground))
    }

    private var conceptTagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("涨停概念")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Text("TOP10")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            FlowLayout(spacing: 8) {
                ForEach(response.conceptTags.prefix(15)) { tag in
                    HStack(spacing: 4) {
                        Text(tag.name)
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("\(tag.count)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(LimitUpLadderView.tagColor(tag.name).opacity(0.12))
                    .foregroundStyle(LimitUpLadderView.tagColor(tag.name).opacity(0.9))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func exportStockCard(_ stock: LimitUpLadderStock) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(stock.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Spacer()

                Text(String(format: "%+.2f%%", stock.pctChg))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(YPColor.up)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            if let first = stock.firstTime, !first.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("首封 \(first)")
                        .font(.caption2)
                }
            }

            if let tags = stock.conceptTags, !tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(LimitUpLadderView.tagColor(tag).opacity(0.12))
                            .foregroundStyle(LimitUpLadderView.tagColor(tag))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func formatTradeDate(_ date: String) -> String {
        guard date.count == 8 else { return date }
        let year = date.prefix(4)
        let month = date[date.index(date.startIndex, offsetBy: 4)..<date.index(date.startIndex, offsetBy: 6)]
        let day = date[date.index(date.startIndex, offsetBy: 6)...]
        return "\(year)-\(month)-\(day)"
    }
}

#Preview {
    NavigationStack {
        LimitUpLadderView()
    }
}
