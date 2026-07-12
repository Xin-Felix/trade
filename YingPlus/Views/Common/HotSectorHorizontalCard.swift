import SwiftUI

// MARK: - 热门板块横向卡片

struct HotSectorHorizontalCard: View {
    let sector: SectorMoneyflowData
    let rank: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(rank)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(rankColor(rank))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()

                if let pct = sector.pctChange {
                    Text(String(format: "%+.2f%%", pct))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(pct >= 0 ? YPColor.up : YPColor.down)
                }
            }

            Text(sector.name ?? "--")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)

            if let lead = sector.leadStock, !lead.isEmpty {
                Text("龙头: \(lead)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if let net = sector.netAmount {
                HStack(spacing: 4) {
                    Image(systemName: net >= 0 ? "arrow.up.circle" : "arrow.down.circle")
                        .font(.caption2)
                    Text(formatNetAmount(net))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(net >= 0 ? YPColor.up : YPColor.down)
            }
        }
        .frame(width: 140, height: 110, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 0.95, green: 0.6, blue: 0.1)
        case 2: return Color(red: 0.65, green: 0.65, blue: 0.7)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.35)
        default: return Color(.tertiaryLabel)
        }
    }

    private func formatNetAmount(_ amount: Double) -> String {
        if abs(amount) >= 10000 {
            return String(format: "%+.1f亿", amount / 10000.0)
        }
        return String(format: "%+.0f万", amount)
    }
}

#Preview {
    HotSectorHorizontalCard(
        sector: SectorMoneyflowData(
            tsCode: "883030.TI",
            tradeDate: "20260712",
            name: "半导体",
            leadStock: "中芯国际",
            closePrice: nil,
            pctChange: 2.35,
            companyNum: nil,
            pctChangeStock: nil,
            netBuyAmount: nil,
            netSellAmount: nil,
            netAmount: 154300
        ),
        rank: 1
    )
    .padding()
}
