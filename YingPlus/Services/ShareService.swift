import SwiftUI
import UIKit

// MARK: - 通用分享服务

/// 统一分享服务：渲染带水印图片 + 弹出系统分享面板
enum ShareService {

    /// 水印配置
    struct WatermarkConfig {
        let appName: String
        let icon: String // SF Symbol name

        static let `default` = WatermarkConfig(appName: "盈多多", icon: "sparkles")
    }

    // MARK: - 渲染图片（带水印）

    /// 将任意 SwiftUI 视图渲染为带水印的 UIImage
    @MainActor
    static func renderImage<V: View>(
        content: V,
        width: CGFloat = 390,
        watermark: WatermarkConfig = .default
    ) -> UIImage? {
        let card = WatermarkedCard(watermark: watermark) { content }
        let renderer = ImageRenderer(content: card)
        renderer.proposedSize = ProposedViewSize(width: width, height: nil)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    /// 将 AI 报告内容渲染为带水印图片
    @MainActor
    static func renderReportImage(
        type: ReportShareCard.ReportType,
        date: String,
        status: String,
        content: String
    ) -> UIImage? {
        let card = ReportShareCard(type: type, date: date, status: status, content: content)
        let renderer = ImageRenderer(content: card)
        renderer.proposedSize = ProposedViewSize(width: 390, height: nil)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    // MARK: - 弹出分享面板

    /// 分享图片（弹出系统 UIActivityViewController）
    @MainActor
    static func shareImage(_ image: UIImage) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        // 找到最顶层的 VC
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        // iPad 需要 popover 锚点
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: 60, width: 0, height: 0)
            popover.permittedArrowDirections = .up
        }

        topVC.present(activityVC, animated: true)
    }

    /// 分享视频文件
    @MainActor
    static func shareVideo(url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: 60, width: 0, height: 0)
            popover.permittedArrowDirections = .up
        }

        topVC.present(activityVC, animated: true)
    }

    /// 一步完成：渲染视图 + 弹出分享
    @MainActor
    static func share<V: View>(content: V, width: CGFloat = 390) {
        guard let image = renderImage(content: content, width: width) else { return }
        shareImage(image)
    }
}

// MARK: - 带水印卡片容器

/// 通用水印容器：底部显示 App 名称水印
struct WatermarkedCard<Content: View>: View {
    let watermark: ShareService.WatermarkConfig
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
            watermarkFooter
        }
        .frame(width: 390)
        .background(Color(.systemBackground))
    }

    private var watermarkFooter: some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: watermark.icon)
                    .font(.system(size: 12, weight: .regular))
                Text(watermark.appName)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color(.tertiarySystemBackground))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
    }
}

// MARK: - 通用分享工具栏按钮

/// 在 toolbar 中使用的通用分享按钮
struct ShareToolbarButton<Content: View>: View {
    let content: () -> Content
    let width: CGFloat

    @State private var isSharing = false

    init(width: CGFloat = 390, @ViewBuilder content: @escaping () -> Content) {
        self.width = width
        self.content = content
    }

    var body: some View {
        Button {
            share()
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .disabled(isSharing)
    }

    private func share() {
        isSharing = true
        Task { @MainActor in
            ShareService.share(content: content(), width: width)
            isSharing = false
        }
    }
}
