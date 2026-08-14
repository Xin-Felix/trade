import SwiftUI

// MARK: - 分时资金流数据模型

struct SectorIntradayItem: Identifiable, Hashable {
    let id = UUID()
    let tsCode: String
    let name: String
    let netAmount: Double      // 累计净流入（元）
    let pctChange: Double?     // 涨跌幅（暂用 up_count/down_count 推算）
    let leadStock: String?     // 龙头股
    let updateTime: String?    // 最近更新时间

    func hash(into hasher: inout Hasher) {
        hasher.combine(tsCode)
    }

    static func == (lhs: SectorIntradayItem, rhs: SectorIntradayItem) -> Bool {
        lhs.tsCode == rhs.tsCode
    }
}

struct SectorIntradayDetail: Identifiable {
    let id = UUID()
    let time: String
    let netAmount: Double
    let cumAmount: Double
}

/// 一帧时间数据：某一分钟所有概念板块的资金快照
struct IntradayFrame {
    let time: String           // "09:30", "09:31" 等
    let items: [SectorIntradayItem]
}

enum SectorType: String, CaseIterable {
    case concept = "概念"
    case industry = "板块"
}

// MARK: - 分时资金流向页面（含播放器）

struct SectorIntradayFlowView: View {
    @State private var allFrames: [IntradayFrame] = []
    @State private var currentIndex: Int = 0
    @State private var isPlaying = false
    @State private var playTimer: Timer?
    @State private var speedMultiplier: Double = 1.0
    @State private var globalMaxAbs: Double = 1
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var tradeDate: String = ""
    @State private var selectedConceptIds: [String] = []
    @State private var selectedIndustryIds: [String] = []
    @State private var showSectorPicker = false
    @State private var sectorType: SectorType = .concept

    private let baseFPS: Double = 12.0
    private let maxSelectionCount: Int = 30
    private let defaultSelectionCount: Int = 20

    private var selectedIds: [String] {
        switch sectorType {
        case .concept: return selectedConceptIds
        case .industry: return selectedIndustryIds
        }
    }

    private var effectiveBubbleCount: Int {
        let count = selectedIds.isEmpty ? 12 : selectedIds.count
        return min(count, maxSelectionCount)
    }

    private var frameInterval: Double {
        1.0 / (baseFPS * speedMultiplier)
    }

    private var currentFrame: IntradayFrame? {
        guard !allFrames.isEmpty, currentIndex < allFrames.count else { return nil }
        return allFrames[currentIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            sectorTypePicker
                .disabled(isLoading)

            if isLoading && allFrames.isEmpty {
                skeletonContent
            } else if let error = loadError, allFrames.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("重试") { Task { await loadRealData() } }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                Spacer()
            } else {
                playerBar

                ScrollView {
                    VStack(spacing: 16) {
                        if let frame = currentFrame {
                            MoneyFlowBubbleView(
                                bubbles: Array(frame.items.prefix(effectiveBubbleCount).map { item in
                                    FlowBubble(
                                        id: item.tsCode,
                                        name: item.name,
                                        netAmount: item.netAmount,
                                        pctChange: item.pctChange ?? 0
                                    )
                                }),
                                title: sectorType == .concept ? "概念板块资金流向" : "行业板块资金流向",
                                referenceScale: globalMaxAbs,
                                moveDuration: isPlaying ? frameInterval : 0.5
                            )
                            .padding(.top, 8)
                        }

                        if let frame = currentFrame {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(sectorType == .concept ? "概念排行" : "板块排行")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text(frame.items.count > 0 ? "共\(frame.items.count)个" : "")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 4)

                                LazyVStack(spacing: 8) {
                                    ForEach(Array(frame.items.sorted { $0.netAmount > $1.netAmount }.enumerated()), id: \.element.id) { index, sector in
                                        NavigationLink {
                                            SectorDetailView(
                                                sector: SectorMoneyflowData(
                                                    tsCode: sector.tsCode,
                                                    tradeDate: tradeDate,
                                                    name: sector.name,
                                                    leadStock: sector.leadStock,
                                                    closePrice: nil,
                                                    pctChange: sector.pctChange,
                                                    companyNum: nil,
                                                    pctChangeStock: nil,
                                                    netBuyAmount: nil,
                                                    netSellAmount: nil,
                                                    netAmount: sector.netAmount / 10000.0
                                                ),
                                                isConcept: sectorType == .concept
                                            )
                                        } label: {
                                            SectorRow(
                                                index: index,
                                                name: sector.name,
                                                leadStock: sector.leadStock,
                                                pctChange: sector.pctChange,
                                                netAmount: sector.netAmount,
                                                netAmountFormatter: formatNetAmount,
                                                showChevron: true
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("分时资金流向")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        Task { await exportVideo() }
                    } label: {
                        Image(systemName: isExporting ? "arrow.clockwise.circle" : "square.and.arrow.up")
                            .font(.body)
                            .foregroundStyle(isExporting ? .secondary : YPColor.accent)
                    }
                    .disabled(isExporting || allFrames.isEmpty)

                    Button {
                        showSectorPicker = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
        }
        .onAppear {
            Task {
                await initializeSelectionIfNeeded()
                await loadRealData()
            }
        }
        .onDisappear { stopPlaying() }
        .onChange(of: selectedConceptIds) { _, newValue in
            saveSelection(newValue, for: .concept)
        }
        .onChange(of: selectedIndustryIds) { _, newValue in
            saveSelection(newValue, for: .industry)
        }
        .sheet(isPresented: $showSectorPicker) {
            SectorPickerView(
                type: sectorType,
                maxSelection: maxSelectionCount,
                selectedIds: sectorBinding
            ) {
                Task { await loadRealData() }
            }
        }
    }

    private var sectorBinding: Binding<[String]> {
        switch sectorType {
        case .concept:
            return $selectedConceptIds
        case .industry:
            return $selectedIndustryIds
        }
    }

    // MARK: - 选择持久化

    private func selectionStorageKey(for type: SectorType) -> String {
        "SectorIntradayFlowView.selectedIds.\(type.rawValue)"
    }

    private func initializeSelectionIfNeeded() async {
        switch sectorType {
        case .concept:
            guard selectedConceptIds.isEmpty else { return }
            selectedConceptIds = await loadSavedOrDefaultSelection(for: .concept)
        case .industry:
            guard selectedIndustryIds.isEmpty else { return }
            selectedIndustryIds = await loadSavedOrDefaultSelection(for: .industry)
        }
    }

    private func loadSavedOrDefaultSelection(for type: SectorType) async -> [String] {
        let key = selectionStorageKey(for: type)
        if let saved = UserDefaults.standard.array(forKey: key) as? [String], !saved.isEmpty {
            return Array(saved.prefix(maxSelectionCount))
        }
        do {
            let (_, defaultIds) = try await ConceptFlowService.fetchSectorOptions(type: type)
            let selected = Array(defaultIds.prefix(defaultSelectionCount))
            UserDefaults.standard.set(selected, forKey: key)
            return selected
        } catch {
            return []
        }
    }

    private func saveSelection(_ ids: [String], for type: SectorType) {
        let key = selectionStorageKey(for: type)
        UserDefaults.standard.set(Array(ids.prefix(maxSelectionCount)), forKey: key)
    }

    // MARK: - 加载真实数据

    private func loadRealData() async {
        loadError = nil
        let ids = selectedIds
        let count = effectiveBubbleCount

        // 1. 先读本地缓存，有就立即展示，避免白屏
        if let cachedData = SectorIntradayCacheService.load(type: sectorType, selectedIds: ids),
           let response = decodeCachedResponse(data: cachedData) {
            await apply(concepts: response.items, tradeDate: response.tradeDate)
            await MainActor.run { isLoading = false }
        } else {
            await MainActor.run { isLoading = true }
        }

        // 2. 请求最新数据并更新缓存
        do {
            let response = try await fetchCurrentResponse(topN: count, ids: ids.isEmpty ? nil : ids)
            if let data = response.encode() {
                SectorIntradayCacheService.save(type: sectorType, selectedIds: ids, data: data)
            }
            await apply(concepts: response.items, tradeDate: response.tradeDate)
        } catch {
            await MainActor.run {
                if allFrames.isEmpty {
                    loadError = "加载失败: \(error.localizedDescription)"
                }
            }
        }

        await MainActor.run { isLoading = false }
    }

    private enum MinuteFlowResponse {
        case concept(ConceptFlowService.ConceptFlowMinuteResponse)
        case industry(ConceptFlowService.IndustryFlowMinuteResponse)

        var tradeDate: String {
            switch self {
            case .concept(let r): return r.data.trade_date
            case .industry(let r): return r.data.trade_date
            }
        }

        var items: [ConceptFlowService.ConceptMinuteItem] {
            switch self {
            case .concept(let r): return r.data.concepts
            case .industry(let r): return r.data.industries
            }
        }

        func encode() -> Data? {
            switch self {
            case .concept(let r): return try? JSONEncoder().encode(r)
            case .industry(let r): return try? JSONEncoder().encode(r)
            }
        }
    }

    private func decodeCachedResponse(data: Data) -> MinuteFlowResponse? {
        switch sectorType {
        case .concept:
            guard let r = try? JSONDecoder().decode(ConceptFlowService.ConceptFlowMinuteResponse.self, from: data) else {
                return nil
            }
            return .concept(r)
        case .industry:
            guard let r = try? JSONDecoder().decode(ConceptFlowService.IndustryFlowMinuteResponse.self, from: data) else {
                return nil
            }
            return .industry(r)
        }
    }

    private func fetchCurrentResponse(topN: Int, ids: [String]?) async throws -> MinuteFlowResponse {
        switch sectorType {
        case .concept:
            let response = try await ConceptFlowService.fetchMinuteFlow(topN: topN, conceptIds: ids)
            return .concept(response)
        case .industry:
            let response = try await ConceptFlowService.fetchIndustryMinuteFlow(topN: topN, industries: ids)
            return .industry(response)
        }
    }

    private func apply(concepts: [ConceptFlowService.ConceptMinuteItem], tradeDate: String) async {
        guard !concepts.isEmpty else {
            await MainActor.run {
                if allFrames.isEmpty {
                    loadError = sectorType == .concept
                        ? "暂无概念资金流数据\n请确认已同步分时数据"
                        : "暂无行业资金流数据\n请确认已同步分时数据"
                }
            }
            return
        }

        let frames = buildFrames(from: concepts)
        guard !frames.isEmpty else {
            await MainActor.run {
                if allFrames.isEmpty { loadError = "分时数据为空" }
            }
            return
        }

        await MainActor.run {
            self.tradeDate = tradeDate
            self.allFrames = frames
            self.currentIndex = 0
            self.globalMaxAbs = frames.flatMap { $0.items.map { abs($0.netAmount) } }.max() ?? 1
        }
    }

    /// 将 API 返回的多概念分钟数据组装成按时间排列的帧
    private func buildFrames(from concepts: [ConceptFlowService.ConceptMinuteItem]) -> [IntradayFrame] {
        // 收集所有时间点
        var allTimes: [String] = []
        for concept in concepts {
            guard let minutes = concept.minutes else { continue }
            for m in minutes {
                if !allTimes.contains(m.time) {
                    allTimes.append(m.time)
                }
            }
        }
        allTimes.sort()

        guard !allTimes.isEmpty else { return [] }

        // 为每个概念建立 time -> MinutePoint 索引
        var conceptMinuteMap: [String: [String: ConceptFlowService.MinutePoint]] = [:]
        for concept in concepts {
            guard let minutes = concept.minutes else { continue }
            var map: [String: ConceptFlowService.MinutePoint] = [:]
            for m in minutes {
                map[m.time] = m
            }
            conceptMinuteMap[concept.concept_id] = map
        }

        // 逐时间点生成帧
        var frames: [IntradayFrame] = []
        for time in allTimes {
            var items: [SectorIntradayItem] = []
            for concept in concepts {
                let minuteMap = conceptMinuteMap[concept.concept_id] ?? [:]
                let point = minuteMap[time]

                // 使用 cumulative_net 作为气泡大小（显示累计资金流）
                // API 返回单位是元，转成万元给气泡显示
                let cumNet = (point?.cumulative_net ?? 0) / 10000.0
                // 用 up_count/down_count 推算涨跌幅
                let upCount = Double(point?.up_count ?? 0)
                let downCount = Double(point?.down_count ?? 0)
                let total = upCount + downCount
                let pctLike = total > 0 ? (upCount - downCount) / total * 5.0 : 0  // 归一化为类涨跌幅

                items.append(SectorIntradayItem(
                    tsCode: concept.concept_id,
                    name: concept.concept_name,
                    netAmount: cumNet,
                    pctChange: pctLike,
                    leadStock: "\(concept.stock_count)只",
                    updateTime: time
                ))
            }
            frames.append(IntradayFrame(time: time, items: items))
        }

        return frames
    }

    // MARK: - 播放控制栏

    private var sectorTypePicker: some View {
        Picker("板块类型", selection: $sectorType) {
            ForEach(SectorType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 12)
        .onChange(of: sectorType) { _, _ in
            stopPlaying()
            currentIndex = 0
            allFrames = []
            Task {
                await initializeSelectionIfNeeded()
                await loadRealData()
            }
        }
    }

    private var playerBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button { togglePlay() } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(YPColor.accent)
                }

                Text(currentFrame?.time ?? "--:--")
                    .font(.title3).fontWeight(.bold).monospacedDigit()

                Spacer()

                HStack(spacing: 6) {
                    ForEach([0.5, 1.0, 2.0], id: \.self) { mult in
                        Button {
                            speedMultiplier = mult
                            if isPlaying { stopPlaying(); startPlaying() }
                        } label: {
                            Text(String(format: "%gx", mult))
                                .font(.caption2)
                                .fontWeight(speedMultiplier == mult ? .bold : .regular)
                                .foregroundStyle(speedMultiplier == mult ? .white : .secondary)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(speedMultiplier == mult ? YPColor.accent : Color(.tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }

            if !allFrames.isEmpty {
                Slider(
                    value: Binding(
                        get: { Double(currentIndex) },
                        set: { currentIndex = Int($0) }
                    ),
                    in: 0...Double(max(allFrames.count - 1, 1)),
                    step: 1
                )
                .tint(YPColor.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .overlay(alignment: .bottom) {
            if isExporting {
                VStack(spacing: 6) {
                    Text("导出中 \(Int(exportProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                    ProgressView(value: exportProgress)
                        .tint(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - 骨架屏

    private var skeletonContent: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    playerBarSkeleton

                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: max(280, min(geometry.size.height * 0.42, 480)))
                        .padding(.horizontal)
                        .padding(.top, 16)

                    LazyVStack(spacing: 8) {
                        ForEach(0..<8, id: \.self) { _ in
                            SkeletonRow()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)

                    Spacer(minLength: 40)
                }
                .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
            }
        }
    }

    private var playerBarSkeleton: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Circle().fill(Color(.tertiarySystemFill)).frame(width: 28, height: 28)
                RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill)).frame(width: 60, height: 22)
                Spacer()
                RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill)).frame(width: 120, height: 22)
                RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill)).frame(width: 28, height: 22)
            }
            RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill)).frame(height: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - 播放控制

    private func togglePlay() {
        if isPlaying {
            stopPlaying()
        } else {
            startPlaying()
        }
    }

    private func startPlaying() {
        isPlaying = true
        playTimer = Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { _ in
            DispatchQueue.main.async {
                if currentIndex < allFrames.count - 1 {
                    currentIndex += 1
                } else {
                    currentIndex = 0
                }
            }
        }
    }

    private func stopPlaying() {
        isPlaying = false
        playTimer?.invalidate()
        playTimer = nil
    }

    // MARK: - 视频导出

    @MainActor
    private func exportVideo() async {
        guard !allFrames.isEmpty else { return }
        stopPlaying()
        isExporting = true
        exportProgress = 0

        let exportFPS: Int = 60
        let renderSize = CGSize(width: 390, height: 440)
        let dataFrameInterval = 1.0 / (baseFPS * speedMultiplier)
        let videoFramesPerData = max(Int(dataFrameInterval * Double(exportFPS)), 1)
        let totalVideoFrames = allFrames.count * videoFramesPerData
        let count = effectiveBubbleCount

        do {
            let url = try await VideoRecorder.streamRecord(
                totalFrames: totalVideoFrames,
                fps: exportFPS,
                renderSize: renderSize,
                progress: { p in exportProgress = p }
            ) { frameIndex in
                let dataIdx = min(frameIndex / videoFramesPerData, allFrames.count - 1)
                let nextDataIdx = min(dataIdx + 1, allFrames.count - 1)
                let subProgress = Double(frameIndex % videoFramesPerData) / Double(videoFramesPerData)
                let simTime = Double(frameIndex) / Double(exportFPS)

                let frameA = allFrames[dataIdx]
                let frameB = allFrames[nextDataIdx]

                let bubbles: [FlowBubble] = (0..<min(count, frameA.items.count)).map { i in
                    let a = frameA.items[i]
                    let b = i < frameB.items.count ? frameB.items[i] : a
                    let lerpAmount = a.netAmount + (b.netAmount - a.netAmount) * subProgress
                    let lerpPct = (a.pctChange ?? 0) + ((b.pctChange ?? 0) - (a.pctChange ?? 0)) * subProgress
                    return FlowBubble(id: a.tsCode, name: a.name, netAmount: lerpAmount, pctChange: lerpPct)
                }

                let time = dataIdx < allFrames.count ? allFrames[dataIdx].time : ""
                let sectorTitle = sectorType == .concept ? "概念" : "行业"
                let todayStr: String = {
                    let fmt = DateFormatter()
                    fmt.dateFormat = "yyyy-MM-dd"
                    return fmt.string(from: Date())
                }()

                return ZStack(alignment: .bottomTrailing) {
                    MoneyFlowBubbleView(
                        bubbles: bubbles,
                        title: "\(sectorTitle)板块资金流向 \(todayStr) \(time)",
                        referenceScale: globalMaxAbs,
                        moveDuration: 0,
                        simulatedTime: simTime
                    )

                    // 水印
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("盈多多")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Capsule())
                    .padding(10)
                }
                .background(Color(.systemBackground))
            }

            ShareService.shareVideo(url: url)
        } catch {
            print("[Export] 失败: \(error)")
        }

        isExporting = false
        exportProgress = 0
    }

    // MARK: - Helpers

    private func formatNetAmount(_ amount: Double) -> String {
        // amount 已经是万元单位
        if abs(amount) >= 10000 {
            return String(format: "%+.1f亿", amount / 10000.0)
        }
        return String(format: "%+.0f万", amount)
    }
}

enum IntradaySortType {
    case netAmount
    case pctChange
}

// MARK: - 分时详情页（单个概念板块）

struct SectorIntradayDetailView: View {
    let sector: SectorIntradayItem
    let tradeDate: String

    @State private var minuteData: [ConceptFlowService.MinutePoint] = []
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard
                chartSection
                timelineSection
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle(sector.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("关闭") { dismiss() }
            }
        }
        .task { await loadDetail() }
    }

    private var summaryCard: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("累计净流入")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatNet(sector.netAmount))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(sector.netAmount >= 0 ? YPColor.up : YPColor.down)
            }

            if let pct = sector.pctChange {
                VStack(spacing: 4) {
                    Text("强弱指标")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%+.2f", pct))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(pct >= 0 ? YPColor.up : YPColor.down)
                }
            }

            if let lead = sector.leadStock {
                VStack(spacing: 4) {
                    Text("成分股")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(lead)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var chartSection: some View {
        VStack(spacing: 8) {
            Text("分时资金流曲线")
                .font(.caption)
                .foregroundStyle(.secondary)

            if minuteData.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 160)
                    .overlay(
                        isLoading
                            ? AnyView(ProgressView())
                            : AnyView(Text("暂无数据").font(.caption).foregroundStyle(.tertiary))
                    )
            } else {
                // 简易折线图
                GeometryReader { geo in
                    let width = geo.size.width
                    let height = geo.size.height
                    let values = minuteData.map { $0.cumulative_net }
                    let maxVal = values.map { abs($0) }.max() ?? 1
                    let midY = height / 2

                    ZStack {
                        // 零轴
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: midY))
                            p.addLine(to: CGPoint(x: width, y: midY))
                        }
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)

                        // 累计净流入曲线
                        Path { p in
                            for (i, val) in values.enumerated() {
                                let x = width * CGFloat(i) / CGFloat(max(values.count - 1, 1))
                                let y = midY - CGFloat(val / maxVal) * (midY - 10)
                                if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                                else { p.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .stroke(
                            (minuteData.last?.cumulative_net ?? 0) >= 0 ? YPColor.up : YPColor.down,
                            lineWidth: 1.5
                        )
                    }
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .background(Color(.tertiarySystemFill).clipShape(RoundedRectangle(cornerRadius: 8)))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("分时明细")
                .font(.headline)

            if minuteData.isEmpty {
                Text(isLoading ? "加载中..." : "暂无数据")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            } else {
                // 显示关键时间点
                let keyPoints = stride(from: 0, to: minuteData.count, by: max(minuteData.count / 10, 1))
                ForEach(Array(keyPoints), id: \.self) { idx in
                    let point = minuteData[idx]
                    HStack {
                        Text(point.time)
                            .font(.caption).monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 45, alignment: .leading)
                        Text(formatNet(point.cumulative_net))
                            .font(.caption).fontWeight(.medium)
                            .foregroundStyle(point.cumulative_net >= 0 ? YPColor.up : YPColor.down)
                        Spacer()
                        Text("入 \(formatShort(point.inflow))")
                            .font(.caption2).foregroundStyle(YPColor.up)
                        Text("出 \(formatShort(point.outflow))")
                            .font(.caption2).foregroundStyle(YPColor.down)
                    }
                    .padding(.vertical, 4)
                    if idx < minuteData.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private func loadDetail() async {
        isLoading = true
        do {
            let response = try await ConceptFlowService.fetchConceptTrend(
                conceptId: sector.tsCode,
                tradeDate: tradeDate.isEmpty ? nil : tradeDate
            )
            await MainActor.run {
                minuteData = response.data.minutes
                isLoading = false
            }
        } catch {
            print("[Detail] 加载失败: \(error)")
            await MainActor.run { isLoading = false }
        }
    }

    private func formatNet(_ amount: Double) -> String {
        // amount 单位是元，转万元显示
        let wan = amount / 10000.0
        if abs(wan) >= 10000 {
            return String(format: "%+.1f亿", wan / 10000.0)
        }
        return String(format: "%+.0f万", wan)
    }

    private func formatShort(_ amount: Double) -> String {
        // amount 单位是元
        let wan = amount / 10000.0
        if abs(wan) >= 10000 {
            return String(format: "%.1f亿", wan / 10000.0)
        }
        return String(format: "%.0f万", wan)
    }
}

// MARK: - 板块选择器（概念/行业通用）

struct SectorPickerView: View {
    let type: SectorType
    let maxSelection: Int
    @Binding var selectedIds: [String]
    var onDone: () -> Void

    @State private var options: [SectorOptionItem] = []
    @State private var defaultIds: [String] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var filteredOptions: [SectorOptionItem] {
        if searchText.isEmpty { return options }
        return options.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var pickerTitle: String {
        type == .concept ? "选择概念" : "选择行业"
    }

    private var sectionTitle: String {
        "已选 \(selectedIds.count)/\(maxSelection) 个\(type == .concept ? "概念" : "行业")"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField(type == .concept ? "搜索概念" : "搜索行业", text: $searchText)
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
                        Section(sectionTitle) {
                            ForEach(filteredOptions) { option in
                                Button {
                                    toggleSelection(option.id)
                                } label: {
                                    HStack {
                                        Image(systemName: selectedIds.contains(option.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedIds.contains(option.id) ? YPColor.accent : .secondary)
                                        Text(option.name)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Text("\(option.stockCount)只")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                        if option.isDefault {
                                            Text("推荐")
                                                .font(.caption2)
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(YPColor.accent)
                                                .clipShape(RoundedRectangle(cornerRadius: 3))
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(selectedIds.count >= maxSelection && !selectedIds.contains(option.id))
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
                    Button("查看热门") {
                        selectedIds = Array(defaultIds.prefix(maxSelection))
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
        .task { await loadOptions() }
    }

    private func toggleSelection(_ id: String) {
        if let idx = selectedIds.firstIndex(of: id) {
            selectedIds.remove(at: idx)
        } else if selectedIds.count < maxSelection {
            selectedIds.append(id)
        }
    }

    private func loadOptions() async {
        do {
            let (loadedOptions, loadedDefaults) = try await ConceptFlowService.fetchSectorOptions(type: type)
            await MainActor.run {
                options = loadedOptions
                defaultIds = loadedDefaults
                if selectedIds.isEmpty {
                    selectedIds = Array(defaultIds.prefix(min(20, maxSelection)))
                }
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
}

#Preview {
    NavigationStack {
        SectorIntradayFlowView()
    }
}
