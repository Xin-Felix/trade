import SwiftUI

// MARK: - 指数项

struct IndexItem: Identifiable, Decodable, Hashable {
    let id = UUID()
    let name: String
    let value: Double
    let change: Double
    let tsCode: String?

    enum CodingKeys: String, CodingKey {
        case name
        case value
        case change
        case tsCode = "ts_code"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(tsCode)
    }

    static func == (lhs: IndexItem, rhs: IndexItem) -> Bool {
        lhs.tsCode == rhs.tsCode
    }
}

// MARK: - 股票行

struct StockRow: View {
    let stock: StockData

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(stock.code)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f", stock.price))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(String(format: "%.2f%%", stock.changePercent))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(stock.changePercent >= 0 ? .red : .green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background((stock.changePercent >= 0 ? Color.red : Color.green).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    StockRow(stock: StockData(
        code: "000001.SZ",
        name: "平安银行",
        price: 12.35,
        changePercent: 1.25,
        updatedAt: "2026-07-08T10:30:00"
    ))
}
