import Foundation

/// H5 页面数据
struct H5PageData: Decodable {
    let slug: String
    let title: String
    let contentType: String
    let content: String
    let renderedHTML: String

    enum CodingKeys: String, CodingKey {
        case slug
        case title
        case contentType = "content_type"
        case content
        case renderedHTML = "rendered_html"
    }
}

/// H5 页面接口响应
struct H5PageResponse: Decodable {
    let success: Bool
    let data: H5PageData
}
