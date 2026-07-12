import Foundation

/// 会员档位
struct MembershipTier: Identifiable, Decodable {
    let id: Int
    let code: String
    let name: String
    let description: String?
    let price: Int
    let durationDays: Int
    let monthlyPointsGrant: Int
    let features: [String]
    let enabled: Int

    enum CodingKeys: String, CodingKey {
        case id, code, name, description, price, features, enabled
        case durationDays = "duration_days"
        case monthlyPointsGrant = "monthly_points_grant"
    }

    var priceYuan: String {
        String(format: "%.2f", Double(price) / 100.0)
    }
}

/// 会员状态
struct MembershipStatus: Decodable {
    let active: Bool
    let tierCode: String?
    let expiresAt: String?
    let balance: Int

    enum CodingKeys: String, CodingKey {
        case active, balance
        case tierCode = "tier_code"
        case expiresAt = "expires_at"
    }
}

/// 会员相关服务
enum MembershipService {
    /// 获取所有会员档位
    static func fetchTiers() async throws -> [MembershipTier] {
        let response: MembershipTierListResponse = try await NetworkService.shared.request(
            APIConfiguration.shared.apiV1URL + "/admin/membership/tiers"
        )
        return response.data
    }

    /// 获取当前用户会员状态
    static func fetchStatus() async throws -> MembershipStatus {
        let response: MembershipStatusResponse = try await NetworkService.shared.request(
            APIConfiguration.shared.apiV1URL + "/membership/status"
        )
        return response.data
    }
}

private struct MembershipTierListResponse: Decodable {
    let success: Bool
    let data: [MembershipTier]
}

private struct MembershipStatusResponse: Decodable {
    let success: Bool
    let data: MembershipStatus
}
