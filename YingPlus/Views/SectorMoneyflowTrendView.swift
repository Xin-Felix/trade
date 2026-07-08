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
    @State private var showSaveSuccess = false

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
        .fullScreenCover(isPresented: $isLandscapePresented) {
            LandscapeChartView(
                series: displayedSeries,
                dates: dates,
                colorMap: displayedColorMap,
                isCumulative: dataMode == .cumulative
            )
        }
        .overlay {
            if showSaveSuccess {
                saveSuccessToast
            }
        }
    }

    private var controlsSection: some View {
        VStack(spacing: 12) {
            Picker("板块类型", selection: $selectedType) {
                Text("行业").tag(SectorMoneyflowType.industry)
                Text("概念").tag(SectorMoneyflowType.concept)
            }
            .pickerStyle(.segmented)

            dataModePicker
            dateRangePicker
            sortAndTopNControls
        }
    }

    private var dataModePicker: some View {
        Picker("数据模式", selection: $dataMode) {
            ForEach(SectorMoneyflowTrendDataMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private var dateRangePicker: some View {
        VStack(spacing: 12) {
            HStack {
                Text("开始日期")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                DatePicker(
                    "",
                    selection: $startDate,
                    in: ...endDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(maxWidth: 120)
            }

            Divider()

            HStack {
                Text("结束日期")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                DatePicker(
                    "",
                    selection: $endDate,
                    in: startDate...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(maxWidth: 120)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var sortAndTopNControls: some View {
        VStack(spacing: 12) {
            HStack {
                Text("排序")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Picker("排序", selection: $selectedSort) {
                    ForEach(SectorMoneyflowTrendSort.allCases) { sort in
                        Text(sort.title).tag(sort)
                    }
                }
                .pickerStyle(.menu)
            }

            Divider()

            HStack {
                Text("展示数量")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Stepper("\(topN)", value: $topN, in: 3...30)
                    .frame(maxWidth: 120)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                saveChartImage()
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.subheadline)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(8)
        .buttonStyle(.plain)
    }

    private var saveSuccessToast: some View {
        VStack {
            Spacer()

            Text("已保存到相册")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.8))
                .clipShape(Capsule())
                .padding(.bottom, 40)
        }
        .transition(.opacity)
    }

    private func loadTrend() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await StockService.fetchSectorMoneyflowTrend(
                sectorType: selectedType,
                startDate: dateFormatter.string(from: startDate),
                endDate: dateFormatter.string(from: endDate),
                topN: topN
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

    private func saveChartImage() {
        guard !displayedSeries.isEmpty else { return }

        let exportView = ChartExportView(
            series: displayedSeries,
            dates: dates,
            colorMap: displayedColorMap,
            isCumulative: dataMode == .cumulative
        )

        let renderer = ImageRenderer(content: exportView)
        renderer.scale = UIScreen.main.scale

        guard let image = renderer.uiImage else { return }

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        withAnimation {
            showSaveSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSaveSuccess = false
            }
        }
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
        VStack(spacing: 8) {
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
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct LegendView: View {
    let series: [SectorMoneyflowSeries]
    let colorMap: [String: Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("图例")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
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
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ChartExportView: View {
    let series: [SectorMoneyflowSeries]
    let dates: [String]
    let colorMap: [String: Color]
    let isCumulative: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(colorScheme == .dark ? UIColor.systemBackground : UIColor.systemBackground)

            VStack(spacing: 12) {
                Text(isCumulative ? "累计资金流向趋势" : "当日资金流向趋势")
                    .font(.headline)

                SectorMoneyflowTrendChartView(
                    series: series,
                    dates: dates,
                    currentDayIndex: max(0, dates.count - 1),
                    colorMap: colorMap
                )
                .frame(height: 500)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                    ForEach(series) { sector in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(colorMap[sector.tsCode] ?? .gray)
                                .frame(width: 8, height: 8)

                            Text(sector.name)
                                .font(.caption)
                                .lineLimit(1)

                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
        .frame(width: 900, height: 700)
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

#Preview {
    NavigationStack {
        SectorMoneyflowTrendView()
    }
}
