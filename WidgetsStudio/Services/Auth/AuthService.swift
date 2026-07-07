import Foundation

enum AuthService {
    /// 登录接口占位
    /// - Parameters:
    ///   - username: 用户名/手机号
    ///   - password: 密码
    /// - Returns: 登录成功后的 token
    static func login(username: String, password: String) async throws -> String {
        let request = LoginRequest(username: username, password: password)
        let response: LoginResponse = try await NetworkService.shared.request(
            APIConfiguration.shared.baseURL + "/auth/login",
            method: .post,
            body: request
        )
        NetworkService.shared.setAuthToken(response.token)
        return response.token
    }

    static func logout() {
        NetworkService.shared.setAuthToken(nil)
    }
}

struct LoginRequest: Encodable {
    let username: String
    let password: String
}

struct LoginResponse: Decodable {
    let token: String
    let userId: String
}
