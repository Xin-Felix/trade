import SwiftUI

struct SectorMoneyflowTrendChartView: View {
    let series: [SectorMoneyflowSeries]
    let dates: [String]
    let currentDayIndex: Int
    let colorMap: [String: Color]

    @Environment(\.colorScheme) private var colorScheme

    private let topPadding: CGFloat = 16
    private let bottomPadding: CGFloat = 32
    private let leftPadding: CGFloat = 48
    private let rightPadding: CGFloat = 16

    private var bgColor: Color {
        colorScheme == .dark ? Color(red: 0.08, green: 0.08, blue: 0.10) : Color(.systemBackground)
    }

    private var gridColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }

    private var axisTextColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.7) : Color.gray.opacity(0.7)
    }

    private var zeroAxisColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.3)
    }

    private var highlightColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.3)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                bgColor.ignoresSafeArea()

                if series.isEmpty || dates.isEmpty {
                    Text("暂无数据")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    canvas(in: geometry.size)
                }
            }
        }
    }

    private func canvas(in size: CGSize) -> some View {
        let chartRect = CGRect(
            x: leftPadding,
            y: topPadding,
            width: max(0, size.width - leftPadding - rightPadding),
            height: max(0, size.height - topPadding - bottomPadding)
        )

        let yRange = computeYRange()
        let endIndex = min(max(currentDayIndex, 0), dates.count - 1)

        return Canvas { context, _ in
            drawGrid(in: chartRect, yRange: yRange, context: context)
            drawZeroAxis(in: chartRect, yRange: yRange, context: context)
            drawXAxisLabels(in: chartRect, context: context)
            drawYAxisLabels(in: chartRect, yRange: yRange, context: context)
            drawSeries(in: chartRect, yRange: yRange, endIndex: endIndex, context: context)
        }
    }

    private func computeYRange() -> (min: Double, max: Double) {
        let allValues = series.flatMap { $0.values.map(\.netAmount) }
        let minValue = allValues.min() ?? 0
        let maxValue = allValues.max() ?? 0
        let padding = max(abs(minValue), abs(maxValue)) * 0.1
        return (min: min(0, minValue) - padding, max: max(0, maxValue) + padding)
    }

    private func xForIndex(_ index: Int, in rect: CGRect) -> CGFloat {
        guard dates.count > 1 else { return rect.midX }
        let step = rect.width / CGFloat(dates.count - 1)
        return rect.minX + CGFloat(index) * step
    }

    private func yForAmount(_ amount: Double, in rect: CGRect, yRange: (min: Double, max: Double)) -> CGFloat {
        let ratio = (amount - yRange.min) / (yRange.max - yRange.min)
        return rect.maxY - CGFloat(ratio) * rect.height
    }

    private func drawGrid(in rect: CGRect, yRange: (min: Double, max: Double), context: GraphicsContext) {
        let gridCount = 4
        for i in 0...gridCount {
            let value = yRange.min + (yRange.max - yRange.min) * Double(i) / Double(gridCount)
            let y = yForAmount(value, in: rect, yRange: yRange)
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
        }
    }

    private func drawZeroAxis(in rect: CGRect, yRange: (min: Double, max: Double), context: GraphicsContext) {
        let y = yForAmount(0, in: rect, yRange: yRange)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: y))
        path.addLine(to: CGPoint(x: rect.maxX, y: y))
        context.stroke(path, with: .color(zeroAxisColor), lineWidth: 1.5)
    }

    private func drawXAxisLabels(in rect: CGRect, context: GraphicsContext) {
        let labelCount = min(dates.count, 6)
        let step = max(1, (dates.count - 1) / (labelCount - 1))

        for i in stride(from: 0, to: dates.count, by: step) {
            let x = xForIndex(i, in: rect)
            let dateText = formatShortDate(dates[i])
            let text = Text(dateText)
                .font(.system(size: 9))
                .foregroundColor(axisTextColor)
            let resolved = context.resolve(text)
            let size = resolved.measure(in: CGSize(width: 60, height: 20))
            context.draw(text, at: CGPoint(x: x - size.width / 2, y: rect.maxY + 8))
        }
    }

    private func drawYAxisLabels(in rect: CGRect, yRange: (min: Double, max: Double), context: GraphicsContext) {
        let labelCount = 4
        for i in 0...labelCount {
            let value = yRange.min + (yRange.max - yRange.min) * Double(i) / Double(labelCount)
            let y = yForAmount(value, in: rect, yRange: yRange)
            let text = Text(String(format: "%.0f亿", value))
                .font(.system(size: 9))
                .foregroundColor(axisTextColor)
            let resolved = context.resolve(text)
            let size = resolved.measure(in: CGSize(width: 48, height: 20))
            context.draw(text, at: CGPoint(x: rect.minX - size.width - 4, y: y - size.height / 2))
        }
    }

    private func drawSeries(
        in rect: CGRect,
        yRange: (min: Double, max: Double),
        endIndex: Int,
        context: GraphicsContext
    ) {
        for sector in series {
            let values = Array(sector.values.prefix(endIndex + 1))
            guard values.count >= 2 else { continue }

            let color = colorMap[sector.tsCode] ?? .accentColor

            var linePath = Path()
            linePath.move(to: CGPoint(
                x: xForIndex(0, in: rect),
                y: yForAmount(values[0].netAmount, in: rect, yRange: yRange)
            ))

            for index in 1..<values.count {
                linePath.addLine(to: CGPoint(
                    x: xForIndex(index, in: rect),
                    y: yForAmount(values[index].netAmount, in: rect, yRange: yRange)
                ))
            }

            context.stroke(linePath, with: .color(color), lineWidth: 2)

            // 只在当前进度点绘制一个小标记
            if let lastValue = values.last {
                let lastPoint = CGPoint(
                    x: xForIndex(values.count - 1, in: rect),
                    y: yForAmount(lastValue.netAmount, in: rect, yRange: yRange)
                )
                let dotRect = CGRect(x: lastPoint.x - 3, y: lastPoint.y - 3, width: 6, height: 6)
                context.fill(Path(ellipseIn: dotRect), with: .color(color))
                context.stroke(Path(ellipseIn: dotRect), with: .color(bgColor), lineWidth: 1)
            }
        }
    }

    private func drawCurrentDayHighlight(
        in rect: CGRect,
        yRange: (min: Double, max: Double),
        endIndex: Int,
        context: GraphicsContext
    ) {
        let x = xForIndex(endIndex, in: rect)

        var linePath = Path()
        linePath.move(to: CGPoint(x: x, y: rect.minY))
        linePath.addLine(to: CGPoint(x: x, y: rect.maxY))
        context.stroke(
            linePath,
            with: .color(highlightColor),
            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
        )

        let dateText = formatTradeDate(dates[endIndex])
        let text = Text(dateText)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(colorScheme == .dark ? .white : .black)
        let resolved = context.resolve(text)
        let size = resolved.measure(in: CGSize(width: 80, height: 20))
        let labelX = min(max(x - size.width / 2, rect.minX), rect.maxX - size.width)
        let labelRect = CGRect(x: labelX, y: rect.minY - 4, width: size.width + 8, height: size.height + 4)
        context.fill(Path(roundedRect: labelRect, cornerRadius: 4), with: .color(bgColor))
        context.draw(text, at: CGPoint(x: labelRect.midX, y: labelRect.midY))
    }

    private func formatTradeDate(_ dateString: String) -> String {
        guard dateString.count == 8 else { return dateString }
        let year = dateString.prefix(4)
        let month = dateString.dropFirst(4).prefix(2)
        let day = dateString.suffix(2)
        return "\(year)-\(month)-\(day)"
    }

    private func formatShortDate(_ dateString: String) -> String {
        guard dateString.count == 8 else { return dateString }
        let month = dateString.dropFirst(4).prefix(2)
        let day = dateString.suffix(2)
        return "\(month)/\(day)"
    }
}

#Preview {
    let sampleSeries = [
        SectorMoneyflowSeries(
            tsCode: "881001.TI",
            name: "煤炭开采",
            values: [
                SectorMoneyflowTrendPoint(tradeDate: "20250701", netAmount: 12.5, pctChange: 1.2),
                SectorMoneyflowTrendPoint(tradeDate: "20250702", netAmount: -3.2, pctChange: -0.5),
                SectorMoneyflowTrendPoint(tradeDate: "20250703", netAmount: 8.7, pctChange: 0.8),
                SectorMoneyflowTrendPoint(tradeDate: "20250704", netAmount: 15.3, pctChange: 2.1)
            ]
        ),
        SectorMoneyflowSeries(
            tsCode: "881002.TI",
            name: "半导体",
            values: [
                SectorMoneyflowTrendPoint(tradeDate: "20250701", netAmount: -5.1, pctChange: -0.8),
                SectorMoneyflowTrendPoint(tradeDate: "20250702", netAmount: 2.4, pctChange: 0.3),
                SectorMoneyflowTrendPoint(tradeDate: "20250703", netAmount: -8.9, pctChange: -1.2),
                SectorMoneyflowTrendPoint(tradeDate: "20250704", netAmount: -1.5, pctChange: -0.1)
            ]
        )
    ]

    return SectorMoneyflowTrendChartView(
        series: sampleSeries,
        dates: ["20250701", "20250702", "20250703", "20250704"],
        currentDayIndex: 3,
        colorMap: [
            "881001.TI": .red,
            "881002.TI": .green
        ]
    )
    .frame(height: 320)
}
