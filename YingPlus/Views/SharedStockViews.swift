import SwiftUI

// MARK: - 指数项

struct IndexItem: Identifiable, Codable, Hashable, Sendable {
    let id = UUID()
    var name: String
    var value: Double
    var change: Double
    var tsCode: String?

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

// MARK: - 全球市场指数

/// 后端 /global-market/indices 返回的原始数据
struct GlobalMarketIndex: Identifiable, Codable, Sendable {
    let id = UUID()
    let code: String
    let name: String
    let market: String
    let price: Double
    let change: Double
    let changePercent: Double
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case code, name, market, price, change
        case changePercent = "change_percent"
        case updatedAt = "updated_at"
    }

    /// 将英文代码映射为中文显示名称
    var displayName: String {
        switch code {
        case "DJI": return "道琼斯"
        case "SPX": return "标普500"
        case "IXIC": return "纳斯达克"
        case "HSI": return "恒生指数"
        case "HSCEI": return "国企指数"
        case "HSTECH": return "恒生科技"
        case "N225": return "日经225"
        case "KS11": return "韩国综合"
        case "FTSE": return "英国富时100"
        case "DAX", "GDAXI": return "德国DAX"
        case "FCHI": return "法国CAC40"
        case "CSX5P": return "欧洲斯托克50"
        case "IBOVESPA": return "巴西IBOVESPA"
        case "SPTSX": return "加拿大SPTSX"
        case "RTS": return "俄罗斯RTS"
        case "RUT": return "罗素2000"
        default: return name
        }
    }
}

struct GlobalMarketIndicesResponse: Codable, Sendable {
    let success: Bool
    let data: [GlobalMarketIndex]
}

extension IndexItem {
    static func from(globalIndex: GlobalMarketIndex) -> IndexItem {
        IndexItem(
            name: globalIndex.displayName,
            value: globalIndex.price,
            change: globalIndex.changePercent,
            tsCode: globalIndex.code
        )
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
