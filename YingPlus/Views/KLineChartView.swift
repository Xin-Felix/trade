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
                let y = priceHeight * CGFloat(i) / CGFloat(priceGridCount)

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
        let padding = (maxPrice - minPrice) * 0.05
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
