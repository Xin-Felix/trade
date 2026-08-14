import SwiftUI

// MARK: - 市场温度数据模型（兼容旧 API 和新 API）

struct MarketSentiment: Identifiable, Sendable {
    let id = UUID()
    let score: Int
    let label: String
    let reason: String
    let keywords: [String]
    let indicators: MarketPulseIndicatorDisplay?
    let tradeDate: String?
}

/// 前端展示用指标
struct MarketPulseIndicatorDisplay: Sendable {
    let upCount: Int
    let downCount: Int
    let amount: Double       // 成交额（亿）
    let amountChangePct: Double
    let northMoney: Double   // 北向（亿）
    let limitUpCount: Int
    let limitDownCount: Int
    let maxBoard: Int
}

// MARK: - AI 市场温度卡片

struct MarketSentimentCard: View {
    let sentiment: MarketSentiment?
    @State private var showFullSummary = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 顶部：标题 + 等级标签
            header

            if let sentiment {
                // 分数 + 进度条
                scoreSection(sentiment)

                // AI 一句话总结
                if !sentiment.reason.isEmpty {
                    summarySection(sentiment.reason)
                }

                // 关键指标
                if let ind = sentiment.indicators {
                    indicatorsSection(ind)
                }

                // 热点关键词
                if !sentiment.keywords.isEmpty {
                    keywordsSection(sentiment.keywords)
                }
            } else {
                placeholder
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - 头部

    private var header: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "waveform.path.ecg")
                    .font(.subheadline)
                    .foregroundStyle(YPColor.market)
                Text("AI 市场温度")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            Spacer()
            if let sentiment {
                Text(sentiment.label)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(levelColor(sentiment.score))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - 分数

    private func scoreSection(_ sentiment: MarketSentiment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(sentiment.score)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(levelColor(sentiment.score))
                Text("/ 100")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let date = sentiment.tradeDate {
                    Text(formatDate(date))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // 温度条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(gaugeGradient)
                        .frame(width: max(0, geo.size.width * CGFloat(sentiment.score) / 100), height: 10)
                }
            }
            .frame(height: 10)
        }
    }

    // MARK: - AI 总结

    private func summarySection(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundStyle(YPColor.market)
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            showFullSummary = true
        }
        .sheet(isPresented: $showFullSummary) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundStyle(YPColor.market)
                            Text("AI 市场温度")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            if let sentiment {
                                Text(sentiment.label)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(levelColor(sentiment.score))
                                    .clipShape(Capsule())
                            }
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundStyle(YPColor.market)
                                .padding(.top, 3)
                            Text(text)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .lineSpacing(6)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding()
                }
                .navigationTitle("市场分析")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("关闭") { showFullSummary = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - 关键指标

    private func indicatorsSection(_ ind: MarketPulseIndicatorDisplay) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 8) {
            indicatorItem(
                icon: "arrow.up",
                label: "上涨",
                value: "\(ind.upCount)",
                color: YPColor.up
            )
            indicatorItem(
                icon: "arrow.down",
                label: "下跌",
                value: "\(ind.downCount)",
                color: YPColor.down
            )
            indicatorItem(
                icon: "banknote",
                label: "成交额",
                value: formatAmount(ind.amount),
                color: .primary
            )
            indicatorItem(
                icon: "arrow.up.right",
                label: "北向",
                value: String(format: "%+.0f亿", ind.northMoney),
                color: ind.northMoney >= 0 ? YPColor.up : YPColor.down
            )
            indicatorItem(
                icon: "flame",
                label: "涨停",
                value: "\(ind.limitUpCount)",
                color: YPColor.up
            )
            indicatorItem(
                icon: "arrow.up.forward.square",
                label: "连板",
                value: "\(ind.maxBoard)板",
                color: YPColor.market
            )
        }
    }

    private func indicatorItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - 热点关键词

    private func keywordsSection(_ keywords: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "tag")
                    .font(.caption2)
                    .foregroundStyle(YPColor.hot)
                Text("今日热点")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            MarketPulseFlowLayout(spacing: 6) {
                ForEach(keywords.prefix(6), id: \.self) { keyword in
                    Text(keyword)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(YPColor.market)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(YPColor.market.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - 占位符

    private var placeholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 80, height: 40)
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(.tertiarySystemFill))
                .frame(height: 10)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.tertiarySystemFill))
                .frame(height: 16)
        }
    }

    // MARK: - 辅助

    private func levelColor(_ score: Int) -> Color {
        switch score {
        case 0..<20: return Color.red
        case 20..<40: return Color.orange
        case 40..<60: return YPColor.warning
        case 60..<80: return YPColor.market
        default: return YPColor.up
        }
    }

    private var gaugeGradient: LinearGradient {
        LinearGradient(
            colors: [.red, .orange, YPColor.warning, YPColor.market, YPColor.up],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func formatAmount(_ amount: Double) -> String {
        if amount >= 10000 {
            return String(format: "%.1f万亿", amount / 10000)
        }
        return String(format: "%.0f亿", amount)
    }

    private func formatDate(_ dateStr: String) -> String {
        // "2026-07-14" → "07/14"
        let parts = dateStr.split(separator: "-")
        if parts.count >= 3 {
            return "\(parts[1])/\(parts[2])"
        }
        return dateStr
    }
}

// MARK: - 流式布局（关键词标签）- 使用独立命名避免冲突

struct MarketPulseFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, offset) in result.offsets.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, offsets: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            offsets.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), offsets)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        MarketSentimentCard(sentiment: MarketSentiment(
            score: 68,
            label: "偏强",
            reason: "机器人、PCB继续领涨，成交额重新放大，赚钱效应改善，短线仍具参与价值。",
            keywords: ["机器人", "PCB", "AI算力", "军工", "稀土"],
            indicators: MarketPulseIndicatorDisplay(
                upCount: 3180, downCount: 1520,
                amount: 14500, amountChangePct: 8.5,
                northMoney: 35.2,
                limitUpCount: 86, limitDownCount: 4, maxBoard: 6
            ),
            tradeDate: "2026-07-14"
        ))

        MarketSentimentCard(sentiment: nil)
    }
    .padding()
}
