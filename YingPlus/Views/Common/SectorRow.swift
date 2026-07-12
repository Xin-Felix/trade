import SwiftUI

/// 通用板块列表行
struct SectorRow: View {
    let index: Int
    let name: String?
    let leadStock: String?
    let pctChange: Double?
    let netAmount: Double?
    let netAmountFormatter: ((Double) -> String)?
    let showChevron: Bool

    init(
        index: Int = 0,
        name: String?,
        leadStock: String? = nil,
        pctChange: Double? = nil,
        netAmount: Double? = nil,
        netAmountFormatter: ((Double) -> String)? = nil,
        showChevron: Bool = true
    ) {
        self.index = index
        self.name = name
        self.leadStock = leadStock
        self.pctChange = pctChange
        self.netAmount = netAmount
        self.netAmountFormatter = netAmountFormatter
        self.showChevron = showChevron
    }

    var body: some View {
        HStack(spacing: 10) {
            Text("\(index + 1)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(index > 0 && index <= 3 ? YPColor.warning : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(name ?? "--")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let lead = leadStock {
                    Text(lead)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let pct = pctChange {
                Text(String(format: "%+.2f%%", pct))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(pct >= 0 ? YPColor.up : YPColor.down)
                    .frame(width: 60, alignment: .trailing)
            }

            if let net = netAmount {
                Text(netAmountFormatter?(net) ?? String(format: "%.0f亿", net))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(net >= 0 ? YPColor.up : YPColor.down)
                    .frame(width: 45, alignment: .trailing)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    VStack(spacing: 8) {
        SectorRow(index: 0, name: "半导体", leadStock: "中芯国际", pctChange: 2.35, netAmount: 12.5)
        SectorRow(index: 3, name: "新能源", pctChange: -0.85, netAmount: -3.2)
    }
    .padding()
}
