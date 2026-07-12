import Foundation

/// 每日一言数据
struct DailyQuoteData: Identifiable, Codable, Sendable {
    let id: Int
    let content: String
    let author: String?
}

/// 每日一言接口响应包装
struct DailyQuoteResponse: Codable, Sendable {
    let success: Bool
    let data: DailyQuoteData
}
