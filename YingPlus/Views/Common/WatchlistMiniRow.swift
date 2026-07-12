import SwiftUI

// MARK: - 自选紧凑行

struct WatchlistMiniRow: View {
    let stock: StockData

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text(stock.code)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f", stock.price))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(stock.changePercent >= 0 ? YPColor.up : YPColor.down)
                Text(String(format: "%+.2f%%", stock.changePercent))
                    .font(.caption2)
                    .foregroundStyle(stock.changePercent >= 0 ? YPColor.up : YPColor.down)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    WatchlistMiniRow(
        stock: StockData(
            code: "000001.SZ",
            name: "平安银行",
            price: 12.35,
            changePercent: 1.25,
            preClose: 12.2,
            updatedAt: "2026-07-12 10:00:00"
        )
    )
    .padding()
}
