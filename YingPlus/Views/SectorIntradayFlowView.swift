import SwiftUI

// MARK: - 分时资金流数据模型

struct SectorIntradayItem: Identifiable {
    let id = UUID()
    let tsCode: String
    let name: String
    let netAmount: Double      // 净流入（万元）
    let pctChange: Double?     // 涨跌幅
    let leadStock: String?     // 龙头股
    let updateTime: String?    // 最近更新时间
}

struct SectorIntradayDetail: Identifiable {
    let id = UUID()
    let time: String
    let netAmount: Double
    let cumAmount: Double
}

/// 一帧时间数据：某一分钟所有概念板块的资金快照
struct IntradayFrame {
    let time: String           // "09:31", "09:32" 等
    let items: [SectorIntradayItem]
}

// MARK: - 分时资金流向页面（含播放器）

struct SectorIntradayFlowView: View {
    @State private var allFrames: [IntradayFrame] = []
    @State private var currentIndex: Int = 0
    @State private var isPlaying = false
    @State private var playTimer: Timer?
    @State private var speedMultiplier: Double = 1.0 // 0.5x / 1x / 2x
    @State private var selectedSector: SectorIntradayItem?
    @State private var globalMaxAbs: Double = 1
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var showExportDone = false

    // 基础播放速度：12 帧/秒（240 帧约 20 秒播完）
    private let baseFPS: Double = 12.0

    private var frameInterval: Double {
        1.0 / (baseFPS * speedMultiplier)
    }

    private var currentFrame: IntradayFrame? {
        guard !allFrames.isEmpty, currentIndex < allFrames.count else { return nil }
        return allFrames[currentIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            // 播放控制栏
            playerBar

            ScrollView {
                VStack(spacing: 16) {
                    // 气泡动画（加顶部间距）
                    if let frame = currentFrame {
                        MoneyFlowBubbleView(
                            bubbles: frame.items.prefix(12).map { item in
                                FlowBubble(
                                    id: item.tsCode,
                                    name: item.name,
                                    netAmount: item.netAmount,
                                    pctChange: item.pctChange ?? 0
                                )
                            },
                            title: "概念板块资金流向",
                            referenceScale: globalMaxAbs,
                            moveDuration: isPlaying ? frameInterval : 0.5
                        )
                        .padding(.top, 8)
                    }

                    // 当前帧排行列表
                    if let frame = currentFrame {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(frame.items.sorted { $0.netAmount > $1.netAmount }.enumerated()), id: \.element.id) { index, sector in
                                Button {
                                    selectedSector = sector
                                } label: {
                                    sectorRow(index: index, sector: sector)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("分时资金流向")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { generateMockData() }
        .onDisappear { stopPlaying() }
        .sheet(item: $selectedSector) { sector in
            NavigationStack {
                SectorIntradayDetailView(sector: sector)
            }
        }
    }

    // MARK: - 播放控制栏

    private var playerBar: some View {
        VStack(spacing: 8) {
            // 时间 + 播放/暂停
            HStack {
                // 播放按钮
                Button {
                    togglePlay()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(YPColor.accent)
                }

                // 当前时间
                Text(currentFrame?.time ?? "--:--")
                    .font(.title3)
                    .fontWeight(.bold)
                    .monospacedDigit()

                Spacer()

                // 速度控制
                HStack(spacing: 8) {
                    ForEach([0.5, 1.0, 2.0], id: \.self) { mult in
                        Button {
                            speedMultiplier = mult
                            if isPlaying {
                                stopPlaying()
                                startPlaying()
                            }
                        } label: {
                            Text(String(format: "%gx", mult))
                                .font(.caption2)
                                .fontWeight(speedMultiplier == mult ? .bold : .regular)
                                .foregroundStyle(speedMultiplier == mult ? .white : .secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(speedMultiplier == mult ? YPColor.accent : Color(.tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }

                // 帧数
                Text("\(currentIndex + 1)/\(allFrames.count)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(width: 50)

                // 保存视频
                Button {
                    Task { await exportVideo() }
                } label: {
                    Image(systemName: isExporting ? "arrow.clockwise.circle" : "square.and.arrow.down")
                        .font(.body)
                        .foregroundStyle(isExporting ? .secondary : YPColor.accent)
                }
                .disabled(isExporting || allFrames.isEmpty)
            }

            // 进度条
            if !allFrames.isEmpty {
                Slider(
                    value: Binding(
                        get: { Double(currentIndex) },
                        set: { newValue in
                            currentIndex = Int(newValue)
                        }
                    ),
                    in: 0...Double(max(allFrames.count - 1, 1)),
                    step: 1
                )
                .tint(YPColor.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .overlay(alignment: .bottom) {
            if isExporting {
                ProgressView(value: exportProgress)
                    .tint(YPColor.accent)
                    .padding(.horizontal, 16)
            }
        }
        .alert("保存成功", isPresented: $showExportDone) {
            Button("好的") {}
        } message: {
            Text("视频已保存到相册")
        }
    }

    // MARK: - 列表行

    private func sectorRow(index: Int, sector: SectorIntradayItem) -> some View {
        HStack(spacing: 10) {
            Text("\(index + 1)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(index < 3 ? YPColor.warning : .secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(sector.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let lead = sector.leadStock {
                    Text(lead)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let pct = sector.pctChange {
                Text(String(format: "%+.2f%%", pct))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(pct >= 0 ? YPColor.up : YPColor.down)
                    .frame(width: 60, alignment: .trailing)
            }

            Text(formatNetAmount(sector.netAmount))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(sector.netAmount >= 0 ? YPColor.up : YPColor.down)
                .frame(width: 65, alignment: .trailing)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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

        // 每个数据帧对应几个视频帧
        let dataFrameInterval = 1.0 / (baseFPS * speedMultiplier)
        let videoFramesPerData = max(Int(dataFrameInterval * Double(exportFPS)), 1)

        // 第一步：逐帧渲染为 UIImage 数组
        var images: [UIImage] = []
        images.reserveCapacity(allFrames.count * videoFramesPerData)

        for (dataIdx, frame) in allFrames.enumerated() {
            let bubbles = Array(frame.items.prefix(12).map { item in
                FlowBubble(id: item.tsCode, name: item.name, netAmount: item.netAmount, pctChange: item.pctChange ?? 0)
            })

            // 每个数据帧渲染多个视频帧，每帧推进模拟时间
            for subFrame in 0..<videoFramesPerData {
                let videoFrameIndex = dataIdx * videoFramesPerData + subFrame
                let simTime = Double(videoFrameIndex) / Double(exportFPS)

                let view = MoneyFlowBubbleView(
                    bubbles: bubbles,
                    title: "概念板块资金流向 \(frame.time)",
                    referenceScale: globalMaxAbs,
                    moveDuration: 0,
                    simulatedTime: simTime
                )
                .background(Color(.systemBackground))

                if let img = VideoRecorder.renderFrame(view, size: renderSize) {
                    images.append(img)
                }
            }

            exportProgress = Double(dataIdx + 1) / Double(allFrames.count) * 0.7
        }

        guard !images.isEmpty else {
            isExporting = false
            return
        }

        // 第二步：合成视频
        do {
            let url = try await VideoRecorder.createVideo(frames: images, fps: exportFPS) { p in
                exportProgress = 0.7 + p * 0.3 // 编码占30%
            }
            try await VideoRecorder.saveToPhotos(url: url)
            showExportDone = true
            // 清理临时文件
            try? FileManager.default.removeItem(at: url)
        } catch {
            print("[Export] 失败: \(error)")
        }

        isExporting = false
        exportProgress = 0
    }

    // MARK: - Mock 数据生成

    private func generateMockData() {
        let concepts: [(code: String, name: String, lead: String, bias: Double)] = [
            ("885760.TI", "人工智能", "科大讯飞", 800),
            ("885680.TI", "芯片概念", "中芯国际", 500),
            ("885590.TI", "新能源车", "比亚迪", 300),
            ("885410.TI", "光伏概念", "隆基绿能", -200),
            ("885330.TI", "白酒概念", "贵州茅台", 600),
            ("885720.TI", "医药生物", "恒瑞医药", -400),
            ("885540.TI", "军工", "中航电子", 200),
            ("885240.TI", "房地产", "万科A", -600),
            ("885170.TI", "银行", "招商银行", -300),
            ("885440.TI", "消费电子", "立讯精密", 400),
            ("885560.TI", "储能", "宁德时代", 350),
            ("885620.TI", "机器人", "汇川技术", 250),
        ]

        // 生成交易时段时间轴：09:30~11:30(120) + 13:00~15:00(120) = 240 分钟
        var times: [String] = []
        // 上午：09:31 ~ 11:30
        for m in 1...120 {
            let total = 9 * 60 + 30 + m
            times.append(String(format: "%02d:%02d", total / 60, total % 60))
        }
        // 下午：13:01 ~ 15:00
        for m in 1...120 {
            let total = 13 * 60 + m
            times.append(String(format: "%02d:%02d", total / 60, total % 60))
        }

        var frames: [IntradayFrame] = []
        var cumAmounts = concepts.map { _ in 0.0 }
        var velocities = concepts.map { _ in 0.0 }
        var pctChanges = concepts.map { _ in 0.0 }

        for time in times {
            var items: [SectorIntradayItem] = []
            for (i, concept) in concepts.enumerated() {
                // 平滑随机游走：带趋势（bias）+ 惯性（velocity damping）
                let noise = Double.random(in: -300...300)
                let trend = concept.bias * 0.02
                velocities[i] = velocities[i] * 0.9 + (noise + trend) * 0.1
                cumAmounts[i] += velocities[i]
                pctChanges[i] += Double.random(in: -0.02...0.02)

                items.append(SectorIntradayItem(
                    tsCode: concept.code,
                    name: concept.name,
                    netAmount: cumAmounts[i],
                    pctChange: pctChanges[i],
                    leadStock: concept.lead,
                    updateTime: time
                ))
            }
            frames.append(IntradayFrame(time: time, items: items))
        }

        allFrames = frames
        currentIndex = 0
        // 全局最大绝对值作为固定标尺：开盘时都在0轴，随时间才逐渐拉开
        globalMaxAbs = frames.flatMap { $0.items.map { abs($0.netAmount) } }.max() ?? 1
    }

    // MARK: - Helpers

    private func formatNetAmount(_ amount: Double) -> String {
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

    @State private var timelineData: [SectorIntradayDetail] = []
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard
                chartPlaceholder
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
                    Text("涨跌幅")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%+.2f%%", pct))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(pct >= 0 ? YPColor.up : YPColor.down)
                }
            }

            if let lead = sector.leadStock {
                VStack(spacing: 4) {
                    Text("龙头股")
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

    private var chartPlaceholder: some View {
        VStack(spacing: 8) {
            Text("分时资金流曲线")
                .font(.caption)
                .foregroundStyle(.secondary)

            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemFill))
                .frame(height: 160)
                .overlay(
                    Text("等待接口数据...")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("分时明细")
                .font(.headline)
            Text("接口接入后显示")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
        }
    }

    private func loadDetail() async {
        // TODO: 接口接入
    }

    private func formatNet(_ amount: Double) -> String {
        if abs(amount) >= 10000 {
            return String(format: "%+.1f亿", amount / 10000.0)
        }
        return String(format: "%+.0f万", amount)
    }
}

#Preview {
    NavigationStack {
        SectorIntradayFlowView()
    }
}
