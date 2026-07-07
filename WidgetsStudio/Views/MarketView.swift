import SwiftUI

struct MarketView: View {
    @State private var selectedTab = 0

    let watchlist = [
        StockItem(code: "000001", name: "平安银行", price: 12.58, change: 2.35),
        StockItem(code: "000002", name: "万科A", price: 15.32, change: -0.84),
        StockItem(code: "600519", name: "贵州茅台", price: 1688.00, change: 1.12),
        StockItem(code: "00700", name: "腾讯控股", price: 385.20, change: 3.45)
    ]

    let indices = [
        IndexItem(name: "上证指数", value: 3050.23, change: 0.68),
        IndexItem(name: "深证成指", value: 9876.54, change: 1.23),
        IndexItem(name: "创业板指", value: 1890.12, change: -0.45)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    indexSection
                    watchlistSection
                }
                .padding()
            }
            .navigationTitle("行情")
        }
    }

    private var indexSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("大盘指数")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(indices) { index in
                    VStack(spacing: 4) {
                        Text(index.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f", index.value))
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(String(format: "%.2f%%", index.change))
                            .font(.caption)
                            .foregroundStyle(index.change >= 0 ? .red : .green)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("自选股")
                    .font(.headline)
                Spacer()
                Button("管理") {
                    // TODO: 管理自选股
                }
                .font(.caption)
            }

            LazyVStack(spacing: 8) {
                ForEach(watchlist) { stock in
                    StockRow(stock: stock)
                }
            }
        }
    }
}

struct StockRow: View {
    let stock: StockItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.name)
                    .font(.headline)
                Text(stock.code)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f", stock.price))
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(String(format: "%.2f%%", stock.change))
                    .font(.caption)
                    .foregroundStyle(stock.change >= 0 ? .red : .green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background((stock.change >= 0 ? Color.red : Color.green).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StockItem: Identifiable {
    let id = UUID()
    let code: String
    let name: String
    let price: Double
    let change: Double
}

struct IndexItem: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let change: Double
}

#Preview {
    MarketView()
}
