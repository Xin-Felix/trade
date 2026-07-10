import Foundation
import UIKit

// MARK: - 用户信息模型

struct UserProfile: Decodable {
    let id: String
    let email: String
    let name: String?
    let avatar: String?
    let role: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, email, name, avatar, role
        case createdAt = "created_at"
    }
}

struct UserProfileResponse: Decodable {
    let success: Bool
    let data: UserProfile
}

struct UserUpdateBody: Encodable {
    let name: String?
    let avatar: String?
}

struct UploadResponse: Decodable {
    let success: Bool
    let data: UploadData
}

struct UploadData: Decodable {
    let objectKey: String
    let url: String

    enum CodingKeys: String, CodingKey {
        case objectKey = "object_key"
        case url = "signed_url" // 后端字段名仍为 signed_url，但 OSS 已公共读，实际是直接 URL
    }
}

// MARK: - 全局通知

extension Notification.Name {
    /// 用户资料更新后发送，监听方应重新加载用户数据
    static let userProfileUpdated = Notification.Name("userProfileUpdated")
}

// MARK: - 用户服务

enum UserService {

    /// 获取当前用户完整信息
    static func fetchProfile() async throws -> UserProfile {
        let url = APIConfiguration.shared.apiV1URL + "/auth/me"
        let response: UserProfileResponse = try await NetworkService.shared.request(url)
        return response.data
    }

    /// 更新用户信息（昵称、头像 object_key）
    static func updateProfile(name: String? = nil, avatar: String? = nil) async throws -> UserProfile {
        let url = APIConfiguration.shared.apiV1URL + "/auth/me"
        let body = UserUpdateBody(name: name, avatar: avatar)
        let response: UserProfileResponse = try await NetworkService.shared.request(url, method: .put, body: body)
        return response.data
    }

    /// 上传头像到 OSS（multipart/form-data）
    /// - Parameter image: 选择的图片（会压缩到 maxSize 以内）
    /// - Parameter maxSizeKB: 最大允许大小（KB），默认 500KB
    /// - Returns: UploadData 包含 object_key 和访问 URL
    static func uploadAvatar(image: UIImage, maxSizeKB: Int = 500) async throws -> UploadData {
        // 压缩图片
        guard let imageData = compressImage(image, maxSizeKB: maxSizeKB) else {
            throw APIError.httpError(statusCode: 0, message: "图片压缩失败")
        }

        let url = APIConfiguration.shared.apiV1URL + "/upload/avatar"
        return try await uploadMultipart(url: url, imageData: imageData, filename: "avatar.jpg", mimeType: "image/jpeg")
    }

    // MARK: - 图片压缩

    /// 将图片压缩到指定大小以内
    /// - 先缩小分辨率到 maxDimension（默认 800px）
    /// - 再 JPEG 质量递减压缩
    static func compressImage(_ image: UIImage, maxSizeKB: Int = 500, maxDimension: CGFloat = 800) -> Data? {
        // 1. 缩小分辨率
        let resized = resizeImage(image, maxDimension: maxDimension)

        // 2. JPEG 质量递减压缩
        var quality: CGFloat = 0.85
        var data = resized.jpegData(compressionQuality: quality)

        while let d = data, d.count > maxSizeKB * 1024, quality > 0.1 {
            quality -= 0.1
            data = resized.jpegData(compressionQuality: quality)
        }

        return data
    }

    private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Multipart Upload

    private static func uploadMultipart(url urlString: String, imageData: Data, filename: String, mimeType: String) async throws -> UploadData {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = NetworkService.shared.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // 构建 multipart body
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            break
        case 401:
            NetworkService.shared.setAuthToken(nil)
            NotificationCenter.default.post(name: .sessionUnauthorized, object: nil)
            throw APIError.unauthorized
        case 400:
            let message = String(data: data, encoding: .utf8)
            throw APIError.httpError(statusCode: 400, message: message)
        default:
            let message = String(data: data, encoding: .utf8)
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
        }

        do {
            let result = try JSONDecoder().decode(UploadResponse.self, from: data)
            return result.data
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
}
