import Foundation

// MARK: - 积分余额

struct PointsBalance: Decodable {
    let balance: Int
    let totalEarned: Int
    let totalUsed: Int
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case balance
        case totalEarned = "total_earned"
        case totalUsed = "total_used"
        case updatedAt = "updated_at"
    }
}

// MARK: - 积分变动记录

struct PointsRecord: Identifiable, Decodable {
    let id: Int
    let type: PointsRecordType
    let amount: Int
    let balanceAfter: Int
    let source: String
    let description: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, type, amount, source, description
        case balanceAfter = "balance_after"
        case createdAt = "created_at"
    }
}

enum PointsRecordType: String, Decodable, CaseIterable {
    case earn = "earn"
    case use = "use"
    case deduct = "deduct"
    case refund = "refund"
    case manual = "manual"

    var displayName: String {
        switch self {
        case .earn: return "获得"
        case .use: return "使用"
        case .deduct: return "扣减"
        case .refund: return "退还"
        case .manual: return "人工调整"
        }
    }

    var isPositive: Bool {
        self == .earn || self == .refund
    }
}

// MARK: - 积分记录分页数据

struct PointsRecordsData: Decodable {
    let list: [PointsRecord]
    let total: Int
    let page: Int
    let pageSize: Int

    enum CodingKeys: String, CodingKey {
        case list, total, page
        case pageSize = "page_size"
    }
}

// MARK: - 功能权限校验

struct PointsFeaturePermission: Decodable {
    let allowed: Bool
    let reason: String?
    let requiredPoints: Int
    let requiredTier: String?
    let balance: Int

    enum CodingKeys: String, CodingKey {
        case allowed, reason, balance
        case requiredPoints = "required_points"
        case requiredTier = "required_tier"
    }
}

// MARK: - 响应包装

struct PointsBalanceResponse: Decodable {
    let success: Bool
    let data: PointsBalance
}

struct PointsRecordsResponse: Decodable {
    let success: Bool
    let data: PointsRecordsData
}

struct PointsFeaturePermissionResponse: Decodable {
    let success: Bool
    let data: PointsFeaturePermission
}
