import Foundation

/// H5 页面服务
enum H5PageService {
    /// 获取公开 H5 页面内容
    static func fetchH5Page(slug: String) async throws -> H5PageData {
        let url = APIConfiguration.shared.apiV1URL + "/h5-pages/public/\(slug)"
        let response: H5PageResponse = try await NetworkService.shared.request(url)
        return response.data
    }
}
