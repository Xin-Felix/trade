import Foundation
import CryptoKit

/// 通用板块选项（概念/行业共用）
struct SectorOptionItem: Identifiable {
    let id: String
    let name: String
    let stockCount: Int
    let isDefault: Bool
}

/// 概念资金流服务 — 分时资金流动态数据
enum ConceptFlowService {

    // MARK: - 响应模型

    struct ConceptFlowMinuteResponse: Codable {
        let success: Bool
        let data: ConceptFlowMinuteData
    }

    struct ConceptFlowMinuteData: Codable {
        let trade_date: String
        let concepts: [ConceptMinuteItem]
    }

    struct ConceptMinuteItem: Codable {
        let concept_id: String
        let concept_name: String
        let stock_count: Int
        let matched_count: Int?
        let net_inflow: Double
        let inflow: Double
        let outflow: Double
        let minutes: [MinutePoint]?
    }

    struct MinutePoint: Codable {
        let time: String
        let net_inflow: Double
        let inflow: Double
        let outflow: Double
        let cumulative_net: Double
        let total_amount: Double?
        let up_count: Int?
        let down_count: Int?
    }

    // 概念资金流汇总（排名）
    struct ConceptFlowSummaryResponse: Decodable {
        let success: Bool
        let data: ConceptFlowSummaryData
    }

    struct ConceptFlowSummaryData: Decodable {
        let trade_date: String
        let concepts: [ConceptSummaryItem]
    }

    struct ConceptSummaryItem: Decodable {
        let concept_id: String
        let concept_name: String
        let net_inflow: Double
        let inflow: Double
        let outflow: Double
        let stock_count: Int
        let matched_count: Int?
        let up_count: Int?
        let down_count: Int?
    }

    // 单概念分钟走势
    struct ConceptTrendResponse: Decodable {
        let success: Bool
        let data: ConceptTrendData
    }

    struct ConceptTrendData: Decodable {
        let concept_id: String
        let concept_name: String
        let trade_date: String
        let stock_count: Int
        let matched_count: Int?
        let minutes: [MinutePoint]
    }

    // MARK: - API 调用

    /// 获取多概念分钟级资金流走势（气泡动画用）
    static func fetchMinuteFlow(tradeDate: String? = nil, topN: Int = 12, conceptIds: [String]? = nil) async throws -> ConceptFlowMinuteResponse {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/analytics/concept-flow/minute")!
        var queryItems = [URLQueryItem(name: "top_n", value: String(topN))]
        if let date = tradeDate {
            queryItems.append(URLQueryItem(name: "trade_date", value: date))
        }
        if let ids = conceptIds, !ids.isEmpty {
            queryItems.append(URLQueryItem(name: "concept_ids", value: ids.joined(separator: ",")))
        }
        components.queryItems = queryItems

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        return try await NetworkService.shared.request(url)
    }

    /// 获取可选概念列表
    static func fetchAvailableConcepts() async throws -> ConceptListResponse {
        let url = APIConfiguration.shared.apiV1URL + "/analytics/concept-flow/concepts"
        return try await NetworkService.shared.request(url)
    }

    struct ConceptListResponse: Decodable {
        let success: Bool
        let data: ConceptListData
    }

    struct ConceptListData: Decodable {
        let concepts: [ConceptOption]
        let default_ids: [String]
    }

    struct ConceptOption: Decodable, Identifiable {
        let concept_id: String
        let concept_name: String
        let stock_count: Int
        let is_default: Bool

        var id: String { concept_id }
    }

    /// 获取概念资金流日内汇总排名
    static func fetchSummary(tradeDate: String? = nil, topN: Int = 20) async throws -> ConceptFlowSummaryResponse {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/analytics/concept-flow")!
        var queryItems = [URLQueryItem(name: "top_n", value: String(topN))]
        if let date = tradeDate {
            queryItems.append(URLQueryItem(name: "trade_date", value: date))
        }
        components.queryItems = queryItems

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        return try await NetworkService.shared.request(url)
    }

    /// 获取单概念分钟级走势
    static func fetchConceptTrend(conceptId: String, tradeDate: String? = nil) async throws -> ConceptTrendResponse {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/analytics/concept-flow/detail")!
        var queryItems = [URLQueryItem(name: "concept_id", value: conceptId)]
        if let date = tradeDate {
            queryItems.append(URLQueryItem(name: "trade_date", value: date))
        }
        components.queryItems = queryItems

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        return try await NetworkService.shared.request(url)
    }

    // MARK: - 行业板块 API

    /// 获取行业板块分钟级资金流走势
    static func fetchIndustryMinuteFlow(tradeDate: String? = nil, topN: Int = 15, industries: [String]? = nil) async throws -> IndustryFlowMinuteResponse {
        var components = URLComponents(string: APIConfiguration.shared.apiV1URL + "/analytics/industry-flow/minute")!
        var queryItems = [URLQueryItem(name: "top_n", value: String(topN))]
        if let date = tradeDate {
            queryItems.append(URLQueryItem(name: "trade_date", value: date))
        }
        if let ids = industries, !ids.isEmpty {
            queryItems.append(URLQueryItem(name: "industries", value: ids.joined(separator: ",")))
        }
        components.queryItems = queryItems

        guard let url = components.url?.absoluteString else {
            throw APIError.invalidURL
        }

        return try await NetworkService.shared.request(url)
    }

    /// 获取行业列表
    static func fetchAvailableIndustries() async throws -> IndustryListResponse {
        let url = APIConfiguration.shared.apiV1URL + "/analytics/industry-flow/list"
        return try await NetworkService.shared.request(url)
    }

    struct IndustryFlowMinuteResponse: Codable {
        let success: Bool
        let data: IndustryFlowMinuteData
    }

    struct IndustryFlowMinuteData: Codable {
        let trade_date: String
        let industries: [ConceptMinuteItem]  // 复用同样的结构
    }

    struct IndustryListResponse: Decodable {
        let success: Bool
        let data: IndustryListData
    }

    struct IndustryListData: Decodable {
        let industries: [IndustryOption]
        let total: Int
    }

    struct IndustryOption: Decodable, Identifiable {
        let name: String
        let stock_count: Int

        var id: String { name }
    }

    // MARK: - 通用选项加载

    static func fetchSectorOptions(type: SectorType) async throws -> ([SectorOptionItem], [String]) {
        switch type {
        case .concept:
            let response = try await fetchAvailableConcepts()
            let options = response.data.concepts.map {
                SectorOptionItem(
                    id: $0.concept_id,
                    name: $0.concept_name,
                    stockCount: $0.stock_count,
                    isDefault: $0.is_default
                )
            }
            return (options, response.data.default_ids)
        case .industry:
            let response = try await fetchAvailableIndustries()
            let options = response.data.industries.map {
                SectorOptionItem(
                    id: $0.name,
                    name: $0.name,
                    stockCount: $0.stock_count,
                    isDefault: false
                )
            }
            // 行业默认取前 30 个，避免一次加载过多
            let defaultIds = Array(options.prefix(30).map(\.id))
            return (options, defaultIds)
        }
    }
}

// MARK: - 分时资金流向本地缓存

enum SectorIntradayCacheService {
    private static let fileManager = FileManager.default

    private static var cacheDirectory: URL {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let directory = urls[0].appendingPathComponent("sector_intraday_flow", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    private static func cacheFileURL(type: SectorType, selectedIds: [String]) -> URL {
        cacheDirectory.appendingPathComponent("\(cacheKey(type: type, selectedIds: selectedIds)).json")
    }

    private static func cacheKey(type: SectorType, selectedIds: [String]) -> String {
        let sortedIds = selectedIds.sorted().joined(separator: ",")
        let raw = "\(type.rawValue)|\(sortedIds)"
        let hash = SHA256.hash(data: Data(raw.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    static func load(type: SectorType, selectedIds: [String]) -> Data? {
        let url = cacheFileURL(type: type, selectedIds: selectedIds)
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return data
    }

    static func save(type: SectorType, selectedIds: [String], data: Data) {
        let url = cacheFileURL(type: type, selectedIds: selectedIds)
        try? data.write(to: url)
    }

    static func clear(type: SectorType, selectedIds: [String]) {
        let url = cacheFileURL(type: type, selectedIds: selectedIds)
        try? fileManager.removeItem(at: url)
    }

    static func clearAll() {
        try? fileManager.removeItem(at: cacheDirectory)
    }
}
