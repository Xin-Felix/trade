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
    let note: String?
    let createdAt: String

    var id: String { code }

    enum CodingKeys: String, CodingKey {
        case code
        case name
        case tsCode = "ts_code"
        case note
        case createdAt = "created_at"
    }
}

/// 添加持仓请求
struct PortfolioAddBody: Encodable {
    let code: String
    let name: String
    let note: String?
}
