import SwiftUI
import Combine

enum SectorMoneyflowTrendSort: String, CaseIterable, Identifiable {
    case netAmount = "net_amount"
    case cumulativeNetAmount = "cumulative_net_amount"
    case pctChange = "pct_change"
    case name = "name"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .netAmount: return "净流入"
        case .cumulativeNetAmount: return "累计净流入"
        case .pctChange: return "涨跌幅"
        case .name: return "名称"
        }
    }
}

enum SectorMoneyflowTrendDataMode: String, CaseIterable, Identifiable {
    case daily = "daily"
    case cumulative = "cumulative"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return "当日"
        case .cumulative: return "累计"
        }
    }
}

struct SectorMoneyflowTrendView: View {
    @State private var selectedType: SectorMoneyflowType = .industry
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var selectedSort: SectorMoneyflowTrendSort = .netAmount
    @State private var dataMode: SectorMoneyflowTrendDataMode = .daily
    @State private var topN = 10
    @State private var rawSeries: [SectorMoneyflowSeries] = []
    @State private var dates: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isLandscapePresented = false
    @State private var showSectorPicker = false
    @State private var selectedSectorIds: [String] = []

    @State private var displayedSeries: [SectorMoneyflowSeries] = []
    @State private var displayedColorMap: [String: Color] = [:]

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    controlsSection
                    ChartContainerView(
                        series: displayedSeries,
                        dates: dates,
                        colorMap: displayedColorMap,
                        isLoading: isLoading,
                        errorMessage: errorMessage
                    )
                    .overlay(alignment: .topTrailing) {
                        chartActionButtons
                    }
                    LegendView(series: displayedSeries, colorMap: displayedColorMap)
                }
                .padding()
            }
        }
        .navigationTitle("资金流动态趋势")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadTrend()
        }
        .onChange(of: selectedType) { _, _ in
            selectedSectorIds = []
            Task { await loadTrend() }
        }
        .onChange(of: startDate) { _, _ in
            Task { await loadTrend() }
        }
        .onChange(of: endDate) { _, _ in
            Task { await loadTrend() }
        }
        .onChange(of: selectedSort) { _, _ in
            prepareDisplayedData()
        }
        .onChange(of: dataMode) { _, _ in
            prepareDisplayedData()
        }
        .onChange(of: topN) { _, _ in
            Task { await loadTrend() }
        }
        .onChange(of: selectedSectorIds) { _, _ in
            Task { await loadTrend() }
        }
        .fullScreenCover(isPresented: $isLandscapePresented) {
            LandscapeChartView(
                series: displayedSeries,
                dates: dates,
                colorMap: displayedColorMap,
                isCumulative: dataMode == .cumulative
            )
        }
        .sheet(isPresented: $showSectorPicker) {
            TrendSectorPickerView(
                selectedType: selectedType,
                selectedIds: $selectedSectorIds,
                startDate: dateFormatter.string(from: startDate),
                endDate: dateFormatter.string(from: endDate)
            ) {
                Task { await loadTrend() }
            }
        }
    }

    private var controlsSection: some View {
        VStack(spacing: 10) {
            // 板块类型 + 数据模式 并排
            HStack(spacing: 10) {
                Picker("板块类型", selection: $selectedType) {
                    Text("板块").tag(SectorMoneyflowType.industry)
                    Text("概念").tag(SectorMoneyflowType.concept)
                }
                .pickerStyle(.segmented)

                Picker("数据模式", selection: $dataMode) {
                    ForEach(SectorMoneyflowTrendDataMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            // 日期 + 排序 + 数量，合并为一个卡片
            VStack(spacing: 0) {
                HStack {
                    Text("开始")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, alignment: .leading)
                    DatePicker("", selection: $startDate, in: ...endDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    Spacer()
                    Text("结束")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker("", selection: $endDate, in: startDate...Date(), displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider().padding(.leading, 12)

                HStack {
                    Text("排序")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("", selection: $selectedSort) {
                        ForEach(SectorMoneyflowTrendSort.allCases) { sort in
                            Text(sort.title).tag(sort)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider().padding(.leading, 12)

                HStack {
                    Text("展示数量")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Stepper("\(topN)", value: $topN, in: 3...30)
                        .frame(maxWidth: 130)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider().padding(.leading, 12)

                Button {
                    showSectorPicker = true
                } label: {
                    HStack {
                        Text(selectedType == .industry ? "选择板块" : "选择概念")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if selectedSectorIds.isEmpty {
                            Text("全部（Top \(topN)）")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        } else {
                            Text("已选 \(selectedSectorIds.count) 个")
                                .font(.caption)
                                .foregroundStyle(YPColor.accent)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var chartActionButtons: some View {
        HStack(spacing: 8) {
            Button {
                isLandscapePresented = true
            } label: {
                Image(systemName: "rectangle.landscape.rotate")
                    .font(.subheadline)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Button {
                shareChartImage()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(8)
        .buttonStyle(.plain)
    }

    private func loadTrend(forceRefresh: Bool = false) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let policy: CachePolicy = forceRefresh ? .skipCache : .default
            let codes = selectedSectorIds.isEmpty ? nil : selectedSectorIds
            let response = try await StockService.fetchSectorMoneyflowTrend(
                sectorType: selectedType,
                startDate: dateFormatter.string(from: startDate),
                endDate: dateFormatter.string(from: endDate),
                topN: topN,
                tsCodes: codes,
                policy: policy
            )
            rawSeries = response.series
            dates = response.dates
            prepareDisplayedData()
        } catch APIError.unauthorized {
            errorMessage = "未登录，请重新登录"
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
        }
    }

    private func prepareDisplayedData() {
        let sorted = sortSeries(rawSeries)
        let finalSeries = dataMode == .cumulative ? cumulativeSeries(from: sorted) : sorted

        displayedSeries = finalSeries
        displayedColorMap = makeColorMap(for: finalSeries)
    }

    private func sortSeries(_ series: [SectorMoneyflowSeries]) -> [SectorMoneyflowSeries] {
        series.sorted { lhs, rhs in
            switch selectedSort {
            case .netAmount:
                return (lhs.values.last?.netAmount ?? 0) > (rhs.values.last?.netAmount ?? 0)
            case .cumulativeNetAmount:
                let lhsCumulative = lhs.values.reduce(0) { $0 + $1.netAmount }
                let rhsCumulative = rhs.values.reduce(0) { $0 + $1.netAmount }
                return lhsCumulative > rhsCumulative
            case .pctChange:
                return (lhs.values.last?.pctChange ?? 0) > (rhs.values.last?.pctChange ?? 0)
            case .name:
                return lhs.name < rhs.name
            }
        }
    }

    private func cumulativeSeries(from series: [SectorMoneyflowSeries]) -> [SectorMoneyflowSeries] {
        series.map { sector in
            var cumulative: Double = 0
            let cumulativeValues = sector.values.map { point in
                cumulative += point.netAmount
                return SectorMoneyflowTrendPoint(
                    tradeDate: point.tradeDate,
                    netAmount: cumulative,
                    pctChange: point.pctChange
                )
            }
            return SectorMoneyflowSeries(
                tsCode: sector.tsCode,
                name: sector.name,
                values: cumulativeValues
            )
        }
    }

    private func makeColorMap(for series: [SectorMoneyflowSeries]) -> [String: Color] {
        var map: [String: Color] = [:]
        for (index, sector) in series.enumerated() {
            map[sector.tsCode] = sectorColors[index % sectorColors.count]
        }
        return map
    }

    private func shareChartImage() {
        guard !displayedSeries.isEmpty else { return }

        let exportView = ChartExportView(
            series: displayedSeries,
            dates: dates,
            colorMap: displayedColorMap,
            isCumulative: dataMode == .cumulative
        )

        // 横屏比例渲染，避免竖屏裁剪
        guard let image = ShareService.renderImage(content: exportView, width: 800) else { return }
        ShareService.shareImage(image)
    }
}

// MARK: - 子视图

struct ChartContainerView: View {
    let series: [SectorMoneyflowSeries]
    let dates: [String]
    let colorMap: [String: Color]
    let isLoading: Bool
    let errorMessage: String?

    var body: some View {
        Group {
            if isLoading && series.isEmpty {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 80)
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            } else if series.isEmpty {
                Text("暂无数据")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 80)
            } else {
                SectorMoneyflowTrendChartView(
                    series: series,
                    dates: dates,
                    currentDayIndex: max(0, dates.count - 1),
                    colorMap: colorMap
                )
                .frame(height: 320)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .background(Color(.secondarySystemBackground).clipShape(RoundedRectangle(cornerRadius: 10)))
    }
}

struct LegendView: View {
    let series: [SectorMoneyflowSeries]
    let colorMap: [String: Color]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 6) {
            ForEach(series) { sector in
                HStack(spacing: 5) {
                    Circle()
                        .fill(colorMap[sector.tsCode] ?? .gray)
                        .frame(width: 7, height: 7)

                    Text(sector.name)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

struct ChartExportView: View {
    let series: [SectorMoneyflowSeries]
    let dates: [String]
    let colorMap: [String: Color]
    let isCumulative: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text(isCumulative ? "累计资金流向趋势" : "当日资金流向趋势")
                .font(.headline)
                .padding(.top, 8)

            SectorMoneyflowTrendChartView(
                series: series,
                dates: dates,
                currentDayIndex: max(0, dates.count - 1),
                colorMap: colorMap
            )
            .frame(height: 420)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 6) {
                ForEach(series) { sector in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(colorMap[sector.tsCode] ?? .gray)
                            .frame(width: 7, height: 7)

                        Text(sector.name)
                            .font(.system(size: 11))
                            .lineLimit(1)

                        Spacer()
                    }
                }
            }
            .padding(.bottom, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

// MARK: - 横屏视图

struct LandscapeChartView: View {
    let series: [SectorMoneyflowSeries]
    let dates: [String]
    let colorMap: [String: Color]
    let isCumulative: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        LandscapeHostingController {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    HStack {
                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    SectorMoneyflowTrendChartView(
                        series: series,
                        dates: dates,
                        currentDayIndex: max(0, dates.count - 1),
                        colorMap: colorMap
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                        ForEach(series) { sector in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(colorMap[sector.tsCode] ?? .gray)
                                    .frame(width: 8, height: 8)

                                Text(sector.name)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .ignoresSafeArea()
    }
}

struct LandscapeHostingController<Content: View>: UIViewControllerRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = LandscapeViewController<Content>()
        controller.hostingController = UIHostingController(rootView: content)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

class LandscapeViewController<Content: View>: UIViewController {
    var hostingController: UIHostingController<Content>?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let hostingController = hostingController else { return }
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .landscape
    }

    override var shouldAutorotate: Bool {
        true
    }
}

private let sectorColors: [Color] = [
    Color(red: 0.95, green: 0.25, blue: 0.15),
    Color(red: 0.15, green: 0.75, blue: 0.35),
    Color(red: 0.20, green: 0.50, blue: 0.95),
    Color(red: 0.95, green: 0.60, blue: 0.10),
    Color(red: 0.70, green: 0.25, blue: 0.90),
    Color(red: 0.10, green: 0.70, blue: 0.80),
    Color(red: 0.95, green: 0.35, blue: 0.60),
    Color(red: 0.55, green: 0.75, blue: 0.20),
    Color(red: 0.40, green: 0.35, blue: 0.90),
    Color(red: 0.90, green: 0.55, blue: 0.20)
]

// MARK: - 趋势板块选择器（从趋势 API 加载选项，确保名称一致）

struct TrendSectorPickerView: View {
    let selectedType: SectorMoneyflowType
    @Binding var selectedIds: [String]
    let startDate: String
    let endDate: String
    var onDone: () -> Void

    @State private var allSectors: [(name: String, tsCode: String)] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private let maxSelection = 30

    private var filteredSectors: [(name: String, tsCode: String)] {
        if searchText.isEmpty { return allSectors }
        return allSectors.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.tsCode.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var pickerTitle: String {
        selectedType == .industry ? "选择板块" : "选择概念"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("搜索", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.top, 8)

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    List {
                        Section("已选 \(selectedIds.count)/\(maxSelection)") {
                            ForEach(filteredSectors, id: \.tsCode) { sector in
                                Button {
                                    toggleSelection(sector.name)
                                } label: {
                                    HStack {
                                        Image(systemName: selectedIds.contains(sector.name) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedIds.contains(sector.name) ? YPColor.accent : .secondary)
                                        Text(sector.name)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(selectedIds.count >= maxSelection && !selectedIds.contains(sector.name))
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(pickerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        Button("清空") {
                            selectedIds = []
                        }
                        Button("热门") {
                            // 选择前 10 个（按累计净流入排序，即 API 默认顺序）
                            selectedIds = Array(allSectors.prefix(10).map(\.name))
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                        onDone()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .task { await loadSectors() }
    }

    private func toggleSelection(_ name: String) {
        if let idx = selectedIds.firstIndex(of: name) {
            selectedIds.remove(at: idx)
        } else if selectedIds.count < maxSelection {
            selectedIds.append(name)
        }
    }

    private func loadSectors() async {
        do {
            // 请求所有板块（top_n=100）获取完整列表
            let response = try await StockService.fetchSectorMoneyflowTrend(
                sectorType: selectedType,
                startDate: startDate,
                endDate: endDate,
                topN: 100,
                policy: .default
            )
            let sectors = response.series.map { (name: $0.name, tsCode: $0.tsCode) }
            await MainActor.run {
                allSectors = sectors
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
}

#Preview {
    NavigationStack {
        SectorMoneyflowTrendView()
    }
}
