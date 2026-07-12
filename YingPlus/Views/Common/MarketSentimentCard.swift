import SwiftUI

// MARK: - 市场情绪数据模型

struct MarketSentiment: Identifiable, Sendable {
    let id = UUID()
    let score: Int
    let label: String
    let reason: String
}

// MARK: - 市场情绪卡片

struct MarketSentimentCard: View {
    let sentiment: MarketSentiment?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.subheadline)
                    .foregroundStyle(YPColor.market)
                Text("市场情绪")
                    .font(.headline)
                Spacer()
                if let sentiment {
                    Text(sentiment.label)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(sentimentColor(sentiment.score))
                        .clipShape(Capsule())
                }
            }

            if let sentiment {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(sentiment.score)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("/100")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.tertiarySystemFill))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(gaugeGradient)
                                .frame(width: max(0, geo.size.width * CGFloat(sentiment.score) / 100), height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text(sentiment.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            } else {
                placeholder
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var placeholder: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 80, height: 36)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.tertiarySystemFill))
                .frame(height: 8)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.tertiarySystemFill))
                .frame(height: 14)
        }
    }

    private func sentimentColor(_ score: Int) -> Color {
        switch score {
        case 0..<30: return YPColor.down
        case 30..<50: return YPColor.warning
        case 50..<70: return YPColor.market
        default: return YPColor.up
        }
    }

    private var gaugeGradient: LinearGradient {
        LinearGradient(
            colors: [YPColor.down, YPColor.warning, YPColor.market, YPColor.up],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

#Preview {
    VStack {
        MarketSentimentCard(sentiment: MarketSentiment(score: 62, label: "中性偏多", reason: "大盘温和震荡，北向资金净流入，热点板块轮动。"))
        MarketSentimentCard(sentiment: nil)
    }
    .padding()
}
