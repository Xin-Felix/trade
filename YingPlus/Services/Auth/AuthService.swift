import Foundation

enum AuthService {
    /// 邮箱登录（密码方式，兼容旧接口）
    static func login(email: String, password: String) async throws -> String {
        let request = EmailLoginRequest(email: email, password: password)
        let response: TokenResponse = try await NetworkService.shared.request(
            APIConfiguration.shared.apiV1URL + "/auth/login/email",
            method: .post,
            body: request
        )
        try setSession(response)
        return response.accessToken
    }

    /// 开发环境快速登录（测试账号）
    static func loginWithTestAccount() async throws -> String {
        try await login(email: "1538933906@qq.com", password: "123456")
    }

    /// 发送邮箱验证码
    static func sendEmailCode(email: String) async throws {
        let request = EmailCodeRequest(email: email)
        try await NetworkService.shared.requestVoid(
            APIConfiguration.shared.apiV1URL + "/auth/email/code",
            method: .post,
            body: request
        )
    }

    /// 校验邮箱验证码并自动注册登录
    static func verifyEmailCode(email: String, code: String) async throws -> String {
        let request = EmailCodeVerifyRequest(email: email, code: code)
        let response: TokenResponse = try await NetworkService.shared.request(
            APIConfiguration.shared.apiV1URL + "/auth/email/verify",
            method: .post,
            body: request
        )
        try setSession(response)
        return response.accessToken
    }

    /// 从 Keychain 恢复登录态
    @discardableResult
    static func restoreSession() -> String? {
        guard let token = KeychainService.shared.read() else {
            return nil
        }
        NetworkService.shared.setAuthToken(token)
        return token
    }

    /// 登出并清理本地凭证
    static func logout() {
        NetworkService.shared.setAuthToken(nil)
        KeychainService.shared.delete()
    }

    private static func setSession(_ response: TokenResponse) throws {
        NetworkService.shared.setAuthToken(response.accessToken)
        // Keychain 在模拟器上可能保存失败，开发环境忽略该错误
        try? KeychainService.shared.save(response.accessToken)
    }
}

struct EmailLoginRequest: Encodable {
    let email: String
    let password: String
}

struct EmailCodeRequest: Encodable {
    let email: String
    let purpose: String = "login"
}

struct EmailCodeVerifyRequest: Encodable {
    let email: String
    let code: String
    let purpose: String = "login"
}

struct TokenResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let user: User?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case user
    }
}

struct User: Decodable {
    let id: String
    let email: String
    let name: String?
}
