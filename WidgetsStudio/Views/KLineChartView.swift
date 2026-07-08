import SwiftUI

struct KLineChartView: View {
    let data: [KlineData]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if data.isEmpty {
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
        let padding: CGFloat = 8
        let chartWidth = size.width - padding * 2
        let chartHeight = size.height - padding * 2

        let sorted = data.sorted { $0.tradeDate < $1.tradeDate }
        let minPrice = sorted.map(\.low).min() ?? 0
        let maxPrice = sorted.map(\.high).max() ?? 0
        let range = maxPrice - minPrice

        guard range > 0, !sorted.isEmpty else {
            return AnyView(
                Text("数据异常")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        }

        let candleWidth = chartWidth / CGFloat(sorted.count) * 0.7
        let spacing = chartWidth / CGFloat(sorted.count)

        return AnyView(
            Canvas { context, _ in
                for (index, kline) in sorted.enumerated() {
                    let x = padding + CGFloat(index) * spacing + spacing / 2

                    let highY = padding + chartHeight * CGFloat((maxPrice - kline.high) / range)
                    let lowY = padding + chartHeight * CGFloat((maxPrice - kline.low) / range)
                    let openY = padding + chartHeight * CGFloat((maxPrice - kline.open) / range)
                    let closeY = padding + chartHeight * CGFloat((maxPrice - kline.close) / range)

                    let isRising = kline.close >= kline.open
                    let color = isRising ? Color.red : Color.green

                    // 影线
                    let shadowPath = Path { path in
                        path.move(to: CGPoint(x: x, y: highY))
                        path.addLine(to: CGPoint(x: x, y: lowY))
                    }
                    context.stroke(shadowPath, with: .color(color), lineWidth: 1)

                    // 实体
                    let bodyTop = min(openY, closeY)
                    let bodyHeight = max(abs(closeY - openY), 1)
                    let bodyRect = CGRect(
                        x: x - candleWidth / 2,
                        y: bodyTop,
                        width: candleWidth,
                        height: bodyHeight
                    )
                    context.fill(Path(bodyRect), with: .color(color))
                }
            }
        )
    }
}

#Preview {
    KLineChartView(data: [
        KlineData(tsCode: "000001.SZ", tradeDate: "20240101", period: "D", open: 10, high: 12, low: 9, close: 11, volume: 1000, amount: nil),
        KlineData(tsCode: "000001.SZ", tradeDate: "20240102", period: "D", open: 11, high: 13, low: 10, close: 12, volume: 1200, amount: nil),
        KlineData(tsCode: "000001.SZ", tradeDate: "20240103", period: "D", open: 12, high: 12.5, low: 9.5, close: 10, volume: 900, amount: nil)
    ])
    .frame(height: 240)
    .padding()
}
