import SwiftUI

/// 报告分享卡片：用于生成带水印的分享图片
struct ReportShareCard: View {
    enum ReportType: String {
        case morning = "AI 晨报"
        case review = "AI 每日复盘"
        case advice = "AI 仓位建议"

        var icon: String {
            switch self {
            case .morning: return "sunrise.fill"
            case .review: return "doc.text.magnifyingglass"
            case .advice: return "chart.pie.fill"
            }
        }

        var themeColor: Color {
            YPColor.ai
        }
    }

    let type: ReportType
    let date: String
    let status: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            contentSection
            footerWatermark
        }
        .frame(width: 390)
        .background(Color(.systemBackground))
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: type.icon)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(type.themeColor)
                .frame(width: 48, height: 48)
                .background(type.themeColor.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 5) {
                Text(type.rawValue)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.primary)

                HStack(spacing: 10) {
                    Text(date)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)

                    statusBadge
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(type.themeColor.opacity(0.05))
    }

    private var statusBadge: some View {
        let (label, color) = statusInfo(status)
        return Text(label)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.10))
            .clipShape(Capsule())
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            markdownContent(content)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
    }

    @ViewBuilder
    private func markdownContent(_ content: String) -> some View {
        let blocks = splitIntoBlocks(content)
        ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
            renderBlock(block)
                .padding(.bottom, index < blocks.count - 1 ? blockSpacing(for: block) : 0)
        }
    }

    /// 智能分块：确保每个标题独立成块，正文按段落分组
    private func splitIntoBlocks(_ content: String) -> [String] {
        var blocks: [String] = []
        var currentBlock: [String] = []
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // 空行 → 结束当前块
            if trimmed.isEmpty {
                if !currentBlock.isEmpty {
                    blocks.append(currentBlock.joined(separator: "\n"))
                    currentBlock = []
                }
                continue
            }

            // 标题行 → 先结束前一块，标题独立成块
            if trimmed.hasPrefix("# ") || trimmed.hasPrefix("## ") || trimmed.hasPrefix("### ") {
                if !currentBlock.isEmpty {
                    blocks.append(currentBlock.joined(separator: "\n"))
                    currentBlock = []
                }
                blocks.append(trimmed)
                continue
            }

            // 普通行追加到当前块
            currentBlock.append(trimmed)
        }

        if !currentBlock.isEmpty {
            blocks.append(currentBlock.joined(separator: "\n"))
        }

        return blocks
    }

    @ViewBuilder
    private func renderBlock(_ block: String) -> some View {
        let trimmed = block.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            Color.clear.frame(height: 6)
        } else if trimmed.hasPrefix("# ") {
            let text = String(trimmed.dropFirst(2)).components(separatedBy: .newlines).first ?? ""
            blockTitle(text, size: 20)
        } else if trimmed.hasPrefix("## ") {
            let text = String(trimmed.dropFirst(3)).components(separatedBy: .newlines).first ?? ""
            blockTitle(text, size: 17)
        } else if trimmed.hasPrefix("### ") {
            let text = String(trimmed.dropFirst(4)).components(separatedBy: .newlines).first ?? ""
            blockTitle(text, size: 16)
        } else if trimmed.hasPrefix("> ") {
            Text(String(trimmed.dropFirst(2)))
                .font(.system(size: 14, weight: .regular))
                .italic()
                .foregroundStyle(.secondary)
                .padding(.leading, 12)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            let lines = trimmed.components(separatedBy: .newlines)
            // 检测无 Markdown 标记的短标题：第一行很短且后续还有正文
            if lines.count > 1, let first = lines.first, isImplicitTitle(first) {
                VStack(alignment: .leading, spacing: 8) {
                    blockTitle(first, size: 17)
                    let rest = lines.dropFirst().joined(separator: "\n")
                    renderRichParagraph(rest)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color(.secondaryLabel))
                        .lineSpacing(8)
                }
            } else if lines.count == 1, isImplicitTitle(trimmed) {
                blockTitle(trimmed, size: 17)
            } else if lines.allSatisfy({ $0.trimmingCharacters(in: .whitespaces).hasPrefix("- ") || $0.trimmingCharacters(in: .whitespaces).hasPrefix("* ") }) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        listItem(line)
                    }
                }
            } else {
                renderRichParagraph(trimmed)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(.secondaryLabel))
                    .lineSpacing(8)
            }
        }
    }

    private func isImplicitTitle(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        guard !trimmed.hasPrefix("- "), !trimmed.hasPrefix("* ") else { return false }
        // 短句、不含标点、不以数字编号结尾，视为小标题
        let charCount = trimmed.count
        let hasPunctuation = trimmed.contains("，") || trimmed.contains("。") || trimmed.contains("；") || trimmed.contains("：")
        return charCount <= 14 && !hasPunctuation
    }

    private func blockTitle(_ text: String, size: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(.primary)
            .padding(.top, size == 20 ? 10 : (size == 17 ? 6 : 4))
    }

    private func listItem(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let text = String(trimmed.dropFirst(2))
        return HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(type.themeColor)
                .frame(width: 14, alignment: .center)
            renderRichParagraph(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color(.secondaryLabel))
                .lineSpacing(6)
        }
    }

    private func renderRichParagraph(_ text: String) -> Text {
        var result = Text("")
        let boldPattern = try? NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*", options: [])
        guard let pattern = boldPattern else { return Text(text) }

        let nsRange = NSRange(location: 0, length: text.utf16.count)
        let matches = pattern.matches(in: text, options: [], range: nsRange)

        var lastIndex = text.startIndex
        for match in matches {
            guard let fullRange = Range(match.range, in: text),
                  let contentRange = Range(match.range(at: 1), in: text) else { continue }
            let before = String(text[lastIndex..<fullRange.lowerBound])
            let boldContent = String(text[contentRange])
            result = result + Text(before).font(.system(size: 14, weight: .regular))
            result = result + Text(boldContent).font(.system(size: 14, weight: .semibold))
            lastIndex = fullRange.upperBound
        }
        let after = String(text[lastIndex...])
        return result + Text(after).font(.system(size: 14, weight: .regular))
    }

    private func blockSpacing(for block: String) -> CGFloat {
        let trimmed = block.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("# ") { return 16 }
        if trimmed.hasPrefix("## ") { return 14 }
        if trimmed.hasPrefix("### ") { return 10 }
        return 10
    }

    private var footerWatermark: some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .regular))
                Text("盈多多")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color(.tertiarySystemBackground))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
    }

    private func statusInfo(_ status: String) -> (String, Color) {
        switch status {
        case "success": return ("已生成", YPColor.success)
        case "failed": return ("失败", YPColor.risk)
        case "running": return ("生成中", YPColor.warning)
        default: return ("待生成", .gray)
        }
    }
}

/// 报告分享服务：渲染卡片为图片并通过系统分享面板分享
enum ReportShareService {
    /// 将分享卡片渲染为 UIImage（已含水印）
    @MainActor
    static func renderImage(type: ReportShareCard.ReportType, date: String, status: String, content: String) -> UIImage? {
        ShareService.renderReportImage(type: type, date: date, status: status, content: content)
    }
}

/// 报告分享按钮：在 toolbar 中使用
struct ReportShareToolbarButton: View {
    let type: ReportShareCard.ReportType
    let date: String
    let status: String
    let content: String
    @State private var isSharing = false

    var body: some View {
        Button {
            shareReport()
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .disabled(isSharing)
    }

    private func shareReport() {
        isSharing = true
        Task { @MainActor in
            if let image = ShareService.renderReportImage(type: type, date: date, status: status, content: content) {
                ShareService.shareImage(image)
            }
            isSharing = false
        }
    }
}

#Preview {
    ReportShareCard(
        type: .morning,
        date: "2026-07-12",
        status: "success",
        content: "# 今日晨报\n\n大盘整体震荡，建议关注科技股和新能源板块。市场成交量较昨日有所萎缩，北向资金净流入约 30 亿元。\n\n## 重点个股\n- 平安银行：震荡整理，关注 10 日均线支撑\n- 宁德时代：业绩超预期，高开高走\n- 比亚迪：新能源车销量创新高\n\n**风险提示**：以上建议仅供参考，不构成投资建议。"
    )
}
