import SwiftUI

struct KLineChartView: View {
    let data: [KlineData]
    @Binding var selectedKline: KlineData?

    @Environment(\.colorScheme) private var colorScheme

    // 视图状态
    @State private var candleWidth: CGFloat = 10
    @State private var candleSpacing: CGFloat = 4
    @State private var offsetX: CGFloat = 0
    @State private var chartSize: CGSize = .zero
    @State private var selectedIndex: Int? = nil
    @State private var showCursor = false

    // Gesture 临时状态
    @State private var lastCandleWidth: CGFloat = 10
    @State private var lastCandleSpacing: CGFloat = 4
    @State private var lastOffsetX: CGFloat = 0
    @State private var pinchScale: CGFloat = 1.0

    // 交互状态：区分平移与十字光标
    @State private var dragStartTime: Date?
    @State private var isPanMode = false
    @State private var isCursorMode = false

    // 颜色配置（A 股：红涨绿跌）
    private let upColor = Color(red: 0.95, green: 0.25, blue: 0.15)
    private let downColor = Color(red: 0.15, green: 0.75, blue: 0.35)

    private var bgColor: Color {
        colorScheme == .dark ? Color(red: 0.08, green: 0.08, blue: 0.10) : Color(.systemBackground)
    }

    private var gridColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }

    private var axisTextColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.7) : Color.gray.opacity(0.7)
    }

    private var cursorColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.4)
    }

    private var cursorLabelBg: Color {
        colorScheme == .dark ? Color.black.opacity(0.7) : Color.white.opacity(0.9)
    }

    private var separatorColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.12)
    }

    // 布局
    private let rightPadding: CGFloat = 64
    private let leftPadding: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                bgColor.ignoresSafeArea()

                if data.isEmpty {
                    Text("暂无数据")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    chartContent(in: geometry.size)
                }
            }
            .onAppear {
                chartSize = geometry.size
                resetVisibleRange(size: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                chartSize = newSize
            }
            .onChange(of: data) { _, _ in
                resetVisibleRange(size: chartSize)
            }
            .onChange(of: selectedIndex) { _, newIndex in
                updateSelectedKline()
            }
            .onChange(of: showCursor) { _, isShowing in
                if !isShowing {
                    selectedKline = nil
                } else {
                    updateSelectedKline()
                }
            }
        }
    }

    private func updateSelectedKline() {
        let sortedData = data.sorted { $0.tradeDate < $1.tradeDate }
        if let index = selectedIndex, sortedData.indices.contains(index) {
            selectedKline = sortedData[index]
        } else {
            selectedKline = nil
        }
    }

    // MARK: - 主内容

    private func chartContent(in size: CGSize) -> some View {
        let sortedData = data.sorted { $0.tradeDate < $1.tradeDate }
        let visibleRange = visibleIndexRange(in: size, totalCount: sortedData.count)
        let priceRange = priceRange(for: sortedData, in: visibleRange)
        let volumeRange = volumeRange(for: sortedData, in: visibleRange)

        return ZStack {
            // 价格区
            priceChart(
                size: size,
                data: sortedData,
                visibleRange: visibleRange,
                priceRange: priceRange
            )

            // 成交量区（固定底部）
            volumeChart(
                size: size,
                data: sortedData,
                visibleRange: visibleRange,
                volumeRange: volumeRange
            )

            // 分隔线
            separatorLine(in: size)
                .allowsHitTesting(false)

            // 右侧坐标轴标签
            axisLabels(
                size: size,
                priceRange: priceRange,
                volumeRange: volumeRange
            )
            .allowsHitTesting(false)

            // 十字光标
            if showCursor, let selectedIndex = selectedIndex, sortedData.indices.contains(selectedIndex) {
                cursorOverlay(
                    size: size,
                    data: sortedData,
                    index: selectedIndex,
                    priceRange: priceRange,
                    volumeRange: volumeRange
                )
            }
        }
        .contentShape(Rectangle())
        .gesture(
            SimultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        handlePinchChanged(value, size: size)
                    }
                    .onEnded { _ in
                        handlePinchEnded(size: size)
                    },
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDragChanged(value, size: size, totalCount: sortedData.count)
                    }
                    .onEnded { _ in
                        handleDragEnded()
                    }
            )
        )
    }

    // MARK: - 价格区

    private var priceChartHeightRatio: CGFloat { 0.70 }
    private var volumeChartHeightRatio: CGFloat { 0.22 }
    private var gapRatio: CGFloat { 0.08 }

    private func priceChartHeight(in totalHeight: CGFloat) -> CGFloat {
        totalHeight * priceChartHeightRatio
    }

    private func volumeChartHeight(in totalHeight: CGFloat) -> CGFloat {
        totalHeight * volumeChartHeightRatio
    }

    private func volumeChartTop(in totalHeight: CGFloat) -> CGFloat {
        totalHeight * (priceChartHeightRatio + gapRatio)
    }

    private func priceChart(
        size: CGSize,
        data: [KlineData],
        visibleRange: ClosedRange<Int>,
        priceRange: (min: Double, max: Double)
    ) -> some View {
        let height = priceChartHeight(in: size.height)

        return Canvas { context, _ in
            // 横向网格线
            let gridCount = 5
            for i in 0...gridCount {
                let y = height * CGFloat(i) / CGFloat(gridCount)
                let path = Path { path in
                    path.move(to: CGPoint(x: leftPadding, y: y))
                    path.addLine(to: CGPoint(x: size.width - rightPadding, y: y))
                }
                context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }

            // 纵向网格线
            let chartWidth = size.width - leftPadding - rightPadding
            let verticalCount = 6
            for i in 0...verticalCount {
                let x = leftPadding + chartWidth * CGFloat(i) / CGFloat(verticalCount)
                let path = Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }

            // K 线
            let bodyWidth = candleWidth * 0.75

            for index in visibleRange {
                let kline = data[index]
                let x = xPosition(for: index)

                guard x >= -candleWidth, x <= size.width + candleWidth else { continue }

                let isRising = kline.close >= kline.open
                let color = isRising ? upColor : downColor

                let highY = yPositionPrice(for: kline.high, height: height, priceRange: priceRange)
                let lowY = yPositionPrice(for: kline.low, height: height, priceRange: priceRange)
                let openY = yPositionPrice(for: kline.open, height: height, priceRange: priceRange)
                let closeY = yPositionPrice(for: kline.close, height: height, priceRange: priceRange)

                // 影线
                let shadowPath = Path { path in
                    path.move(to: CGPoint(x: x, y: highY))
                    path.addLine(to: CGPoint(x: x, y: lowY))
                }
                context.stroke(shadowPath, with: .color(color), lineWidth: 1)

                // 实体
                let bodyTop = min(openY, closeY)
                let bodyHeight = max(abs(closeY - openY), 1.5)
                let bodyRect = CGRect(
                    x: x - bodyWidth / 2,
                    y: bodyTop,
                    width: bodyWidth,
                    height: bodyHeight
                )

                if isRising {
                    context.fill(Path(bodyRect), with: .color(color))
                } else {
                    context.fill(Path(bodyRect), with: .color(bgColor))
                    context.stroke(Path(bodyRect), with: .color(color), lineWidth: 1)
                }
            }
        }
        .frame(height: height)
        .position(x: size.width / 2, y: height / 2)
        .mask(
            Rectangle()
                .frame(width: size.width - leftPadding - rightPadding, height: height)
                .position(x: (leftPadding + size.width - rightPadding) / 2, y: height / 2)
        )
    }

    // MARK: - 成交量区

    private func volumeChart(
        size: CGSize,
        data: [KlineData],
        visibleRange: ClosedRange<Int>,
        volumeRange: (min: Double, max: Double)
    ) -> some View {
        let height = volumeChartHeight(in: size.height)
        let topY = volumeChartTop(in: size.height)

        return Canvas { context, _ in
            let chartWidth = size.width - leftPadding - rightPadding
            let verticalCount = 6

            // 纵向网格线
            for i in 0...verticalCount {
                let x = leftPadding + chartWidth * CGFloat(i) / CGFloat(verticalCount)
                let path = Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }

            // 成交量柱子
            let barWidth = candleWidth * 0.75

            for index in visibleRange {
                let kline = data[index]
                guard let volume = kline.volume else { continue }

                let x = xPosition(for: index)
                guard x >= -candleWidth, x <= size.width + candleWidth else { continue }

                let isRising = kline.close >= kline.open
                let color = isRising ? upColor : downColor

                let barTop = yPositionVolume(for: volume, height: height, volumeRange: volumeRange)
                let barRect = CGRect(
                    x: x - barWidth / 2,
                    y: barTop,
                    width: barWidth,
                    height: height - barTop
                )

                if isRising {
                    context.fill(Path(barRect), with: .color(color))
                } else {
                    context.fill(Path(barRect), with: .color(bgColor))
                    context.stroke(Path(barRect), with: .color(color), lineWidth: 1)
                }
            }
        }
        .frame(height: height)
        .position(x: size.width / 2, y: topY + height / 2)
        .mask(
            Rectangle()
                .frame(width: size.width - leftPadding - rightPadding, height: height)
                .position(x: (leftPadding + size.width - rightPadding) / 2, y: topY + height / 2)
        )
    }

    // MARK: - 分隔线

    private func separatorLine(in size: CGSize) -> some View {
        let y = size.height * (priceChartHeightRatio + gapRatio / 2)

        return Path { path in
            path.move(to: CGPoint(x: leftPadding, y: y))
            path.addLine(to: CGPoint(x: size.width - rightPadding, y: y))
        }
        .stroke(separatorColor, lineWidth: 1)
    }

    // MARK: - 坐标轴标签

    private func axisLabels(
        size: CGSize,
        priceRange: (min: Double, max: Double),
        volumeRange: (min: Double, max: Double)
    ) -> some View {
        let priceHeight = priceChartHeight(in: size.height)
        let volumeTop = volumeChartTop(in: size.height)
        let priceGridCount = 5

        return ZStack {
            // 价格标签
            ForEach(0...priceGridCount, id: \.self) { i in
                let price = priceRange.max - (priceRange.max - priceRange.min) * Double(i) / Double(priceGridCount)
                let rawY = priceHeight * CGFloat(i) / CGFloat(priceGridCount)
                let y = max(8, min(priceHeight - 8, rawY))

                Text(String(format: "%.2f", price))
                    .font(.system(size: 10))
                    .foregroundStyle(axisTextColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(cursorLabelBg)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .position(x: size.width - rightPadding / 2 + 2, y: y)
            }

            // 成交量最大值标签
            Text(formatVolume(volumeRange.max))
                .font(.system(size: 10))
                .foregroundStyle(axisTextColor)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(cursorLabelBg)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .position(x: size.width - rightPadding / 2 + 2, y: volumeTop + 10)
        }
    }

    // MARK: - 十字光标

    private func cursorOverlay(
        size: CGSize,
        data: [KlineData],
        index: Int,
        priceRange: (min: Double, max: Double),
        volumeRange: (min: Double, max: Double)
    ) -> some View {
        let kline = data[index]
        let x = xPosition(for: index)
        let priceHeight = priceChartHeight(in: size.height)
        let volumeTop = volumeChartTop(in: size.height)
        let volumeHeight = volumeChartHeight(in: size.height)
        let closeY = yPositionPrice(for: kline.close, height: priceHeight, priceRange: priceRange)

        return ZStack {
            // 竖线
            Path { path in
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: volumeTop + volumeHeight))
            }
            .stroke(cursorColor, style: StrokeStyle(lineWidth: 0.5, dash: [4, 2]))

            // 价格横线
            Path { path in
                path.move(to: CGPoint(x: leftPadding, y: closeY))
                path.addLine(to: CGPoint(x: size.width - rightPadding, y: closeY))
            }
            .stroke(cursorColor, style: StrokeStyle(lineWidth: 0.5, dash: [4, 2]))

            // 当前价格标签
            Text(String(format: "%.2f", kline.close))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(cursorLabelBg)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .position(x: size.width - rightPadding / 2, y: closeY)

            // 信息卡片
            VStack(alignment: .leading, spacing: 4) {
                Text(formatTradeDate(kline.tradeDate))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        labelValue("开", kline.open)
                        labelValue("高", kline.high)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        labelValue("低", kline.low)
                        labelValue("收", kline.close)
                    }
                }

                if let volume = kline.volume {
                    labelValue("量", volume, formatter: formatVolume)
                }
            }
            .padding(10)
            .background(cursorLabelBg)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .position(x: min(size.width - 130, max(130, x)), y: 55)
        }
    }

    private func labelValue(_ label: String, _ value: Double, formatter: ((Double) -> String)? = nil) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(formatter != nil ? formatter!(value) : String(format: "%.2f", value))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }

    // MARK: - 初始化与计算

    private func resetVisibleRange(size: CGSize) {
        guard !data.isEmpty else { return }
        candleWidth = 10
        candleSpacing = 4
        lastCandleWidth = candleWidth
        lastCandleSpacing = candleSpacing
        selectedIndex = nil
        showCursor = false
        dragStartTime = nil
        isPanMode = false
        isCursorMode = false

        let totalWidth = totalContentWidth(for: data.count)
        let availableWidth = size.width - rightPadding - leftPadding
        guard availableWidth > 0 else {
            offsetX = 0
            lastOffsetX = 0
            return
        }

        if totalWidth > availableWidth {
            offsetX = availableWidth - totalWidth
        } else {
            offsetX = 0
        }
        lastOffsetX = offsetX
    }

    private func totalContentWidth(for count: Int) -> CGFloat {
        CGFloat(count) * (candleWidth + candleSpacing) + candleSpacing
    }

    private func visibleIndexRange(in size: CGSize, totalCount: Int) -> ClosedRange<Int> {
        let unitWidth = candleWidth + candleSpacing
        guard unitWidth > 0, totalCount > 0 else { return 0...0 }

        let startIndex = max(0, Int(floor(-offsetX / unitWidth)))
        guard startIndex < totalCount else { return (totalCount - 1)...(totalCount - 1) }

        let visibleCount = Int(ceil(size.width / unitWidth)) + 1
        let endIndex = min(totalCount - 1, startIndex + visibleCount)
        return startIndex...max(startIndex, endIndex)
    }

    private func priceRange(for data: [KlineData], in range: ClosedRange<Int>) -> (min: Double, max: Double) {
        let slice = Array(data[range])
        let minPrice = slice.map(\.low).min() ?? 0
        let maxPrice = slice.map(\.high).max() ?? 0
        let range = maxPrice - minPrice
        // 上下各留 12% 边距，避免 K 线实体/影线被截断或与坐标轴标签重叠
        let padding = max(range * 0.12, 0.05)
        return (minPrice - padding, maxPrice + padding)
    }

    private func volumeRange(for data: [KlineData], in range: ClosedRange<Int>) -> (min: Double, max: Double) {
        let slice = Array(data[range])
        let maxVolume = slice.compactMap(\.volume).max() ?? 0
        return (0, maxVolume * 1.2)
    }

    private func xPosition(for index: Int) -> CGFloat {
        let unitWidth = candleWidth + candleSpacing
        return offsetX + CGFloat(index) * unitWidth + unitWidth / 2
    }

    private func yPositionPrice(for price: Double, height: CGFloat, priceRange: (min: Double, max: Double)) -> CGFloat {
        let range = priceRange.max - priceRange.min
        guard range > 0 else { return height / 2 }
        return height * CGFloat((priceRange.max - price) / range)
    }

    private func yPositionVolume(for volume: Double, height: CGFloat, volumeRange: (min: Double, max: Double)) -> CGFloat {
        let range = volumeRange.max - volumeRange.min
        guard range > 0 else { return 0 }
        return height * (1 - CGFloat((volume - volumeRange.min) / range))
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 100_000_000 {
            return String(format: "%.2f亿", volume / 100_000_000)
        } else if volume >= 10_000 {
            return String(format: "%.2f万", volume / 10_000)
        } else {
            return String(format: "%.0f", volume)
        }
    }

    private func formatTradeDate(_ dateString: String) -> String {
        guard dateString.count == 8 else { return dateString }
        let year = dateString.prefix(4)
        let month = dateString.dropFirst(4).prefix(2)
        let day = dateString.suffix(2)
        return "\(year)-\(month)-\(day)"
    }

    // MARK: - Gesture 处理

    private func handlePinchChanged(_ value: CGFloat, size: CGSize) {
        let scale = value
        let newWidth = max(4, min(40, lastCandleWidth * scale))
        let newSpacing = max(2, min(16, lastCandleSpacing * scale))

        candleWidth = newWidth
        candleSpacing = newSpacing
    }

    private func handlePinchEnded(size: CGSize) {
        lastCandleWidth = candleWidth
        lastCandleSpacing = candleSpacing
        pinchScale = 1.0
        clampOffsetX(size: size)
        lastOffsetX = offsetX
    }

    private func handleDragChanged(_ value: DragGesture.Value, size: CGSize, totalCount: Int) {
        let translation = value.translation.width
        let horizontalDelta = abs(translation)
        let verticalDelta = abs(value.translation.height)

        if dragStartTime == nil {
            dragStartTime = Date()
        }

        guard let startTime = dragStartTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)

        if isCursorMode {
            updateSelectedIndex(at: value.location.x, totalCount: totalCount)
        } else if isPanMode {
            offsetX = lastOffsetX + translation
            clampOffsetX(size: size)
        } else if horizontalDelta > 8 || verticalDelta > 8 {
            if elapsed < 0.25 {
                isPanMode = true
                offsetX = lastOffsetX + translation
                clampOffsetX(size: size)
            }
        } else if elapsed >= 0.3 {
            isCursorMode = true
            showCursor = true
            updateSelectedIndex(at: value.location.x, totalCount: totalCount)
        }
    }

    private func handleDragEnded() {
        lastOffsetX = offsetX
        dragStartTime = nil
        isPanMode = false
        isCursorMode = false
        showCursor = false
        selectedIndex = nil
    }

    private func updateSelectedIndex(at x: CGFloat, totalCount: Int) {
        let unitWidth = candleWidth + candleSpacing
        guard unitWidth > 0, totalCount > 0 else { return }
        let index = Int(round((x - offsetX - unitWidth / 2) / unitWidth))
        selectedIndex = max(0, min(totalCount - 1, index))
    }

    private func clampOffsetX(size: CGSize) {
        let totalWidth = totalContentWidth(for: data.count)
        let maxOffset: CGFloat = 0
        let minOffset = size.width - totalWidth - rightPadding - leftPadding

        if totalWidth <= size.width - rightPadding - leftPadding {
            offsetX = 0
        } else {
            offsetX = min(maxOffset, max(minOffset, offsetX))
        }
    }
}

#Preview {
    KLineChartView(
        data: [
            KlineData(tsCode: "000001.SZ", tradeDate: "20240101", period: "D", open: 10, high: 12, low: 9, close: 11, volume: 1000, amount: nil),
            KlineData(tsCode: "000001.SZ", tradeDate: "20240102", period: "D", open: 11, high: 13, low: 10, close: 12, volume: 1200, amount: nil),
            KlineData(tsCode: "000001.SZ", tradeDate: "20240103", period: "D", open: 12, high: 12.5, low: 9.5, close: 10, volume: 900, amount: nil),
            KlineData(tsCode: "000001.SZ", tradeDate: "20240104", period: "D", open: 10, high: 11, low: 9.8, close: 10.8, volume: 1100, amount: nil),
            KlineData(tsCode: "000001.SZ", tradeDate: "20240105", period: "D", open: 10.8, high: 11.5, low: 10.2, close: 11.2, volume: 1300, amount: nil)
        ],
        selectedKline: .constant(nil)
    )
    .frame(height: 400)
    .padding()
    .background(Color(.systemBackground))
}

// MARK: - 实时分时折线图

/// 实时分时折线图：仅展示当天分钟级收盘价走势
struct IntradayLineChartView: View {
    let data: [IntradayKlineData]
    let preClose: Double?

    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedPoint: IntradayKlineData?
    @State private var showCursor = false

    private let upColor = Color(red: 0.95, green: 0.25, blue: 0.15)
    private let downColor = Color(red: 0.15, green: 0.75, blue: 0.35)

    private var lineColor: Color {
        guard let preClose = preClose, preClose != 0 else { return upColor }
        let latest = data.sorted { $0.datetime < $1.datetime }.last?.close ?? preClose
        return latest >= preClose ? upColor : downColor
    }

    private var bgColor: Color {
        colorScheme == .dark ? Color(red: 0.08, green: 0.08, blue: 0.10) : Color(.systemBackground)
    }

    private var gridColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }

    private var axisTextColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.7) : Color.gray.opacity(0.7)
    }

    private var cursorLabelBg: Color {
        colorScheme == .dark ? Color.black.opacity(0.7) : Color.white.opacity(0.9)
    }

    private var cursorColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.4)
    }

    private let rightPadding: CGFloat = 64
    private let leftPadding: CGFloat = 24
    private let bottomPadding: CGFloat = 28
    private let topPadding: CGFloat = 16

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                bgColor.ignoresSafeArea()

                if data.isEmpty {
                    Text("暂无分时数据")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    chartContent(in: geometry.size)
                }
            }
        }
    }

    private func chartContent(in size: CGSize) -> some View {
        let normalized = normalizedIntradayData(from: data)
        let priceRange = priceRange(for: normalized)

        return ZStack {
            gridLayer(size: size, priceRange: priceRange)
                .allowsHitTesting(false)

            lineLayer(size: size, data: normalized, priceRange: priceRange)
                .allowsHitTesting(false)

            preCloseLayer(size: size, priceRange: priceRange)
                .allowsHitTesting(false)

            axisLabels(size: size, priceRange: priceRange)
                .allowsHitTesting(false)

            if showCursor, let selectedPoint = selectedPoint {
                cursorOverlay(size: size, point: selectedPoint, priceRange: priceRange)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    showCursor = true
                    selectedPoint = nearestPoint(at: value.location.x, size: size, data: normalized)
                }
                .onEnded { _ in
                    showCursor = false
                    selectedPoint = nil
                }
        )
    }

    // MARK: - 数据归一化（兜底后端跨天/缺失数据）

    private func normalizedIntradayData(from data: [IntradayKlineData]) -> [IntradayKlineData] {
        guard let latestDateStr = data.max(by: { $0.datetime < $1.datetime })?.datetime.prefix(8) else { return [] }
        let latestDate = String(latestDateStr)
        let todayData = data.filter { $0.datetime.hasPrefix(latestDate) && $0.datetime.isInTradingHours() }
        guard !todayData.isEmpty else { return [] }

        // 用 tradingMinuteIndex 去重：同一 index 保留最后出现的数据
        var pointsByIndex: [Int: IntradayKlineData] = [:]
        for point in todayData {
            guard let index = point.datetime.tradingMinuteIndex() else { continue }
            pointsByIndex[index] = point
        }

        return pointsByIndex.sorted { $0.key < $1.key }.map { $0.value }
    }

    private func gridLayer(size: CGSize, priceRange: (min: Double, max: Double)) -> some View {
        let chartHeight = size.height - topPadding - bottomPadding
        let chartWidth = size.width - leftPadding - rightPadding

        return Canvas { context, _ in
            let gridCount = 4
            for i in 0...gridCount {
                let y = topPadding + chartHeight * CGFloat(i) / CGFloat(gridCount)
                let path = Path { path in
                    path.move(to: CGPoint(x: leftPadding, y: y))
                    path.addLine(to: CGPoint(x: leftPadding + chartWidth, y: y))
                }
                context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }

            let timeLabels = ["09:30", "10:30", "14:00", "15:00"]
            for label in timeLabels {
                guard let x = xPositionForTime(label, size: size) else { continue }
                let path = Path { path in
                    path.move(to: CGPoint(x: x, y: topPadding))
                    path.addLine(to: CGPoint(x: x, y: topPadding + chartHeight))
                }
                context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }

            // 补一条中间竖线，把坐标系真正四等分
            let midX = leftPadding + chartWidth * 0.5
            let midPath = Path { path in
                path.move(to: CGPoint(x: midX, y: topPadding))
                path.addLine(to: CGPoint(x: midX, y: topPadding + chartHeight))
            }
            context.stroke(midPath, with: .color(gridColor), lineWidth: 0.5)
        }
    }

    private func lineLayer(size: CGSize, data: [IntradayKlineData], priceRange: (min: Double, max: Double)) -> some View {
        Canvas { context, _ in
            guard data.count >= 2 else { return }

            let path = Path { path in
                var first = true
                for point in data {
                    let x = xPosition(for: point.datetime, size: size)
                    let y = yPosition(for: point.close, size: size, priceRange: priceRange)
                    if first {
                        path.move(to: CGPoint(x: x, y: y))
                        first = false
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            context.stroke(
                path,
                with: .color(lineColor),
                lineWidth: 1.0
            )

            if let last = data.last {
                let x = xPosition(for: last.datetime, size: size)
                let y = yPosition(for: last.close, size: size, priceRange: priceRange)
                let dot = Path(ellipseIn: CGRect(x: x - 2.5, y: y - 2.5, width: 5, height: 5))
                context.fill(dot, with: .color(lineColor))
            }
        }
    }

    private func preCloseLayer(size: CGSize, priceRange: (min: Double, max: Double)) -> some View {
        guard let preClose = preClose, preClose >= priceRange.min, preClose <= priceRange.max else {
            return AnyView(EmptyView())
        }

        let y = yPosition(for: preClose, size: size, priceRange: priceRange)
        let chartWidth = size.width - leftPadding - rightPadding

        return AnyView(
            Path { path in
                path.move(to: CGPoint(x: leftPadding, y: y))
                path.addLine(to: CGPoint(x: leftPadding + chartWidth, y: y))
            }
            .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 0.75, dash: [4, 2]))
        )
    }

    private func axisLabels(size: CGSize, priceRange: (min: Double, max: Double)) -> some View {
        let chartHeight = size.height - topPadding - bottomPadding
        let gridCount = 4

        return ZStack {
            ForEach(0...gridCount, id: \.self) { i in
                let price = priceRange.max - (priceRange.max - priceRange.min) * Double(i) / Double(gridCount)
                let rawY = topPadding + chartHeight * CGFloat(i) / CGFloat(gridCount)
                let y = max(topPadding + 6, min(topPadding + chartHeight - 6, rawY))

                Text(String(format: "%.2f", price))
                    .font(.system(size: 10))
                    .foregroundStyle(axisTextColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(cursorLabelBg)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .position(x: size.width - rightPadding / 2 + 2, y: y)
            }

            let timeLabels = ["09:30", "10:30", "14:00", "15:00"]
            ForEach(Array(timeLabels.enumerated()), id: \.offset) { index, label in
                if let x = xPositionForTime(label, size: size) {
                    let labelWidth: CGFloat = 34
                    let alignedX: CGFloat = {
                        if index == 0 {
                            return leftPadding + labelWidth / 2
                        } else if index == timeLabels.count - 1 {
                            return size.width - rightPadding - labelWidth / 2
                        } else {
                            return x
                        }
                    }()
                    let clampedX = max(leftPadding + labelWidth / 2, min(size.width - rightPadding - labelWidth / 2, alignedX))
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundStyle(axisTextColor)
                        .position(x: clampedX, y: size.height - bottomPadding / 2 + 2)
                }
            }
        }
    }

    private func cursorOverlay(size: CGSize, point: IntradayKlineData, priceRange: (min: Double, max: Double)) -> some View {
        let x = xPosition(for: point.datetime, size: size)
        let y = yPosition(for: point.close, size: size, priceRange: priceRange)
        let chartBottom = topPadding + size.height - topPadding - bottomPadding

        let changePercent: Double? = {
            guard let preClose = preClose, preClose != 0 else { return nil }
            return (point.close - preClose) / preClose * 100
        }()

        return ZStack {
            // 竖线
            Path { path in
                path.move(to: CGPoint(x: x, y: topPadding))
                path.addLine(to: CGPoint(x: x, y: chartBottom))
            }
            .stroke(cursorColor, style: StrokeStyle(lineWidth: 0.5, dash: [4, 2]))

            // 价格横线
            Path { path in
                path.move(to: CGPoint(x: leftPadding, y: y))
                path.addLine(to: CGPoint(x: size.width - rightPadding, y: y))
            }
            .stroke(cursorColor, style: StrokeStyle(lineWidth: 0.5, dash: [4, 2]))

            // 当前价格标签（右侧）
            Text(String(format: "%.2f", point.close))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(cursorLabelBg)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .position(x: size.width - rightPadding / 2, y: y)

            // 信息卡片
            VStack(alignment: .leading, spacing: 4) {
                Text(formatHeaderDate(point.datetime))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)

                HStack(spacing: 12) {
                    Text(String(format: "价格: %.2f", point.close))
                        .font(.system(size: 10))
                        .foregroundStyle(.primary)

                    if let changePercent = changePercent {
                        Text(String(format: "%.2f%%", changePercent))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(changePercent >= 0 ? .red : .green)
                    }
                }

                if let volume = point.volume {
                    Text("成交量: \(formatVolume(volume))")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(10)
            .background(cursorLabelBg)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .position(x: min(size.width - 110, max(110, x)), y: topPadding + 45)
        }
    }

    private func nearestPoint(at x: CGFloat, size: CGSize, data: [IntradayKlineData]) -> IntradayKlineData? {
        let chartWidth = size.width - leftPadding - rightPadding
        guard chartWidth > 0, !data.isEmpty else { return nil }

        let clampedX = max(leftPadding, min(size.width - rightPadding, x))
        let ratio = (clampedX - leftPadding) / chartWidth
        let totalMinutes: CGFloat = 240
        let targetIndex = ratio * totalMinutes

        return data.min { lhs, rhs in
            guard let lhsIndex = lhs.datetime.tradingMinuteIndex(),
                  let rhsIndex = rhs.datetime.tradingMinuteIndex() else { return false }
            return abs(CGFloat(lhsIndex) - targetIndex) < abs(CGFloat(rhsIndex) - targetIndex)
        }
    }

    private func formatHeaderDate(_ dateString: String) -> String {
        let parts = dateString.split(separator: " ")
        guard parts.count == 2, parts[0].count == 8 else { return dateString }
        let date = parts[0]
        let time = parts[1]
        return "\(date.prefix(4))-\(date.dropFirst(4).prefix(2))-\(date.suffix(2)) \(time.prefix(5))"
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 100_000_000 {
            return String(format: "%.2f亿", volume / 100_000_000)
        } else if volume >= 10_000 {
            return String(format: "%.2f万", volume / 10_000)
        } else {
            return String(format: "%.0f", volume)
        }
    }

    private func priceRange(for data: [IntradayKlineData]) -> (min: Double, max: Double) {
        let closes = data.map(\.close)
        let minPrice = closes.min() ?? 0
        let maxPrice = closes.max() ?? 0
        let base = preClose ?? ((minPrice + maxPrice) / 2)

        let lower = min(minPrice, base)
        let upper = max(maxPrice, base)
        let range = upper - lower

        // 留出足够边距，避免右侧价格标签和折线顶点溢出绘图区
        let padding = max(range * 0.12, base * 0.015, 0.05)
        return (lower - padding, upper + padding)
    }

    private func xPosition(for datetime: String, size: CGSize) -> CGFloat {
        let chartWidth = size.width - leftPadding - rightPadding
        guard let index = datetime.tradingMinuteIndex() else {
            return leftPadding
        }

        let totalMinutes: CGFloat = 240  // 09:30~11:30(120) + 13:00~15:00(120)
        let ratio = CGFloat(index) / totalMinutes
        return leftPadding + chartWidth * ratio
    }

    private func xPositionForTime(_ time: String, size: CGSize) -> CGFloat? {
        guard let index = time.tradingMinuteIndexForTime() else { return nil }
        let chartWidth = size.width - leftPadding - rightPadding
        let totalMinutes: CGFloat = 240
        return leftPadding + chartWidth * CGFloat(index) / totalMinutes
    }

    private func yPosition(for price: Double, size: CGSize, priceRange: (min: Double, max: Double)) -> CGFloat {
        let chartHeight = size.height - topPadding - bottomPadding
        let range = priceRange.max - priceRange.min
        guard range > 0 else { return topPadding + chartHeight / 2 }
        return topPadding + chartHeight * CGFloat((priceRange.max - price) / range)
    }
}

private extension String {
    /// 判断 "YYYYMMDD HH:MM:SS" 是否在 A 股交易时段内
    func isInTradingHours() -> Bool {
        let components = self.split(separator: " ")
        guard components.count == 2 else { return false }
        let time = components[1]
        let parts = time.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return false }

        let minutes = hour * 60 + minute
        let morningStart = 9 * 60 + 30
        let morningEnd = 11 * 60 + 30
        let afternoonStart = 13 * 60
        let afternoonEnd = 15 * 60

        return (minutes >= morningStart && minutes <= morningEnd) ||
               (minutes >= afternoonStart && minutes <= afternoonEnd)
    }

    /// 将 "YYYYMMDD HH:MM:SS" 转为交易分钟序号
    /// 09:30~11:30 映射到 0~120，13:00~15:00 映射到 120~240，午休直接拼接
    func tradingMinuteIndex() -> Int? {
        let components = self.split(separator: " ")
        guard components.count == 2 else { return nil }
        let time = components[1]
        let parts = time.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }

        let minutes = hour * 60 + minute
        let morningStart = 9 * 60 + 30   // 570
        let morningEnd = 11 * 60 + 30    // 690
        let afternoonStart = 13 * 60     // 780
        let afternoonEnd = 15 * 60       // 900

        if minutes < morningStart {
            return 0
        } else if minutes <= morningEnd {
            return minutes - morningStart
        } else if minutes < afternoonStart {
            return 120
        } else if minutes <= afternoonEnd {
            return 120 + (minutes - afternoonStart)
        } else {
            return 240
        }
    }

    /// 将 "HH:MM" 转为交易分钟序号
    func tradingMinuteIndexForTime() -> Int? {
        let parts = self.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }

        let minutes = hour * 60 + minute
        let morningStart = 9 * 60 + 30
        let morningEnd = 11 * 60 + 30
        let afternoonStart = 13 * 60
        let afternoonEnd = 15 * 60

        if minutes < morningStart {
            return 0
        } else if minutes <= morningEnd {
            return minutes - morningStart
        } else if minutes < afternoonStart {
            return 120
        } else if minutes <= afternoonEnd {
            return 120 + (minutes - afternoonStart)
        } else {
            return 240
        }
    }
}

#Preview {
    IntradayLineChartView(
        data: [
            IntradayKlineData(tsCode: "000001.SZ", datetime: "20240708 09:30:00", period: "1", open: 12.30, high: 12.35, low: 12.28, close: 12.32, volume: 1000, amount: nil),
            IntradayKlineData(tsCode: "000001.SZ", datetime: "20240708 10:30:00", period: "1", open: 12.32, high: 12.38, low: 12.30, close: 12.36, volume: 1200, amount: nil),
            IntradayKlineData(tsCode: "000001.SZ", datetime: "20240708 11:30:00", period: "1", open: 12.36, high: 12.40, low: 12.33, close: 12.35, volume: 900, amount: nil),
            IntradayKlineData(tsCode: "000001.SZ", datetime: "20240708 14:00:00", period: "1", open: 12.35, high: 12.45, low: 12.34, close: 12.42, volume: 1500, amount: nil),
            IntradayKlineData(tsCode: "000001.SZ", datetime: "20240708 15:00:00", period: "1", open: 12.42, high: 12.44, low: 12.38, close: 12.40, volume: 1100, amount: nil)
        ],
        preClose: 12.35
    )
    .frame(height: 240)
    .padding()
    .background(Color(.systemBackground))
}
