import Foundation

/// 持仓列表响应
struct PortfolioResponse: Codable {
    let items: [PortfolioItem]
    let total: Int
}

/// 持仓项
struct PortfolioItem: Codable, Identifiable, Hashable {
    let code: String
    let name: String
    let tsCode: String
    let costPrice: Double?
    let quantity: Double?
    let isMargin: Bool
    let note: String?
    let createdAt: String

    var id: String { code }

    enum CodingKeys: String, CodingKey {
        case code
        case name
        case tsCode = "ts_code"
        case costPrice = "cost_price"
        case quantity
        case isMargin = "is_margin"
        case note
        case createdAt = "created_at"
    }
}

/// 添加持仓请求
struct PortfolioAddBody: Encodable {
    let code: String
    let name: String
    let costPrice: Double?
    let quantity: Double?
    let isMargin: Bool?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case code
        case name
        case costPrice = "cost_price"
        case quantity
        case isMargin = "is_margin"
        case note
    }
}

/// 更新持仓请求
struct PortfolioUpdateBody: Encodable {
    let costPrice: Double?
    let quantity: Double?
    let isMargin: Bool?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case costPrice = "cost_price"
        case quantity
        case isMargin = "is_margin"
        case note
    }
}

extension PortfolioItem {
    /// 持仓市值（基于传入的当前价格）
    func positionValue(at price: Double) -> Double? {
        guard let quantity else { return nil }
        return price * quantity
    }

    /// 持仓成本总额
    var costValue: Double? {
        guard let costPrice, let quantity else { return nil }
        return costPrice * quantity
    }

    /// 浮盈浮亏金额（基于当前价格）
    func unrealizedPnL(at price: Double) -> Double? {
        guard let costPrice, let quantity else { return nil }
        return (price - costPrice) * quantity
    }

    /// 盈亏比例（基于当前价格）
    func pnlPercent(at price: Double) -> Double? {
        guard let costPrice, costPrice != 0 else { return nil }
        return (price - costPrice) / costPrice * 100
    }

    /// 是否已录入完整持仓信息
    var hasPositionDetails: Bool {
        costPrice != nil && quantity != nil
    }
}


// MARK: - 持仓导入

/// 导入持仓请求
struct PortfolioImportBody: Encodable {
    let text: String
}

/// 导入持仓响应
struct PortfolioImportResponse: Decodable {
    let success: Bool
    let imported: [[String: AnyCodableValue]]
    let total: Int
}

/// 通用 JSON 值包装，用于解码 imported 数组中的异构字典
enum AnyCodableValue: Decodable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(String.self) { self = .string(v) }
        else if let v = try? container.decode(Int.self) { self = .int(v) }
        else if let v = try? container.decode(Double.self) { self = .double(v) }
        else if let v = try? container.decode(Bool.self) { self = .bool(v) }
        else { self = .null }
    }
}
