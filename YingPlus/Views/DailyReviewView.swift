import SwiftUI

/// 使用 AttributedString 渲染完整 Markdown（支持标题、列表、加粗、链接等）
private func markdownText(_ content: String) -> some View {
    Group {
        if let attributed = try? AttributedString(
            markdown: content,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .full
            )
        ) {
            Text(attributed)
                .font(.body)
                .foregroundStyle(.primary)
        } else {
            Text(content)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }
}

struct DailyReviewView: View {
    @State private var todayReview: DailyReviewItem?
    @State private var reviews: [DailyReviewItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedReview: DailyReviewItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    todayReviewSection
                    historySection
                }
                .padding()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("AI 每日复盘")
            .refreshable {
                await loadData()
            }
            .task {
                await loadData()
            }
            .sheet(item: $selectedReview) { review in
                DailyReviewDetailView(review: review)
            }
        }
    }

    // MARK: - 今日复盘

    private var todayReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeaderView(icon: "sparkles", title: "今日复盘", color: YPColor.ai)
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if let review = todayReview {
                if review.status == "success", let summary = effectiveSummary(for: review) {
                    reviewContentCard(summary: summary) {
                        selectedReview = review
                    }
                } else if review.status == "failed" {
                    failedCard(message: review.errorMessage ?? "生成失败")
                } else {
                    pendingCard(message: "复盘正在生成中，请稍后再试")
                }
            } else if let error = errorMessage {
                failedCard(message: error)
            } else {
                emptyCard(message: "今日复盘尚未生成")
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 历史复盘

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "clock.arrow.circlepath", title: "历史复盘", color: YPColor.info)

            if reviews.isEmpty {
                emptyCard(message: "暂无历史复盘")
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(reviews) { review in
                        historyRow(review: review)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func historyRow(review: DailyReviewItem) -> some View {
        Button {
            selectedReview = review
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.reportDate ?? "未知日期")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 6) {
                        statusBadge(status: review.status)

                        if let preview = effectiveSummary(for: review) {
                            Text(preview)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.quaternary)
            }
            .padding(12)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 子视图

    private func reviewContentCard(summary: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(summary)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(4)

            Button(action: action) {
                HStack {
                    Spacer()
                    Text("查看完整复盘")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(YPColor.aiGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
    }

    private func emptyCard(message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 24)
            Spacer()
        }
    }

    private func pendingCard(message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.9)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 24)
            Spacer()
        }
    }

    private func failedCard(message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(YPColor.risk)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 24)
            Spacer()
        }
    }

    private func statusBadge(status: String) -> some View {
        let (label, color): (String, Color) = {
            switch status {
            case "success": return ("已生成", YPColor.success)
            case "failed": return ("失败", YPColor.risk)
            case "running": return ("生成中", YPColor.warning)
            default: return ("待生成", .gray)
            }
        }()

        return Text(label)
            .font(.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - 摘要显示

    private func effectiveSummary(for review: DailyReviewItem) -> String? {
        if let summary = review.summary, !summary.isEmpty {
            return summary
        }
        guard let content = review.content, !content.isEmpty else { return nil }
        let endIndex = content.index(content.startIndex, offsetBy: min(100, content.count), limitedBy: content.endIndex) ?? content.endIndex
        return String(content[..<endIndex])
    }

    // MARK: - 数据加载

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // 今日复盘：404 表示尚未生成，显示空状态；取消则忽略
        do {
            todayReview = try await DailyReviewService.fetchTodayReview()
        } catch APIError.httpError(let statusCode, _) where statusCode == 404 {
            todayReview = nil
        } catch APIError.paymentRequired {
            // 402 已由 NetworkService 通知全局，这里不处理
            errorMessage = "该功能需要会员权限"
        } catch APIError.unauthorized {
            errorMessage = "登录已过期"
        } catch is CancellationError {
            // 页面切换或刷新竞争导致，不展示错误
        } catch {
            if errorMessage == nil {
                errorMessage = "加载失败：\(error.localizedDescription)"
            }
        }

        // 历史复盘：与今日复盘独立，避免一个失败影响另一个
        do {
            let history = try await DailyReviewService.fetchReviews(page: 1, pageSize: 20)
            reviews = history.list
        } catch APIError.httpError(let statusCode, _) where statusCode == 404 {
            reviews = []
        } catch APIError.paymentRequired {
            // 402 已由 NetworkService 通知全局
        } catch APIError.unauthorized {
            if errorMessage == nil {
                errorMessage = "登录已过期"
            }
        } catch is CancellationError {
            // 忽略
        } catch {
            if errorMessage == nil {
                errorMessage = "加载失败：\(error.localizedDescription)"
            }
        }
    }
}

// MARK: - 复盘详情页

struct DailyReviewDetailView: View {
    let review: DailyReviewItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                headerView
                    .padding()
                Divider()
                markdownContentView
            }
            .navigationTitle("复盘详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        if review.status == "success", let content = review.content {
                            ReportShareToolbarButton(
                                type: .review,
                                date: review.reportDate ?? "未知日期",
                                status: review.status,
                                content: content
                            )
                        }

                        Button("关闭") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(review.reportDate ?? "未知日期")
                    .font(.headline)

                HStack(spacing: 8) {
                    let (label, color) = statusInfo(review.status)
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(color.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
    }

    private var markdownContentView: some View {
        Group {
            if review.status == "success", let content = review.content {
                H5WebView(htmlString: MarkdownHTMLRenderer.render(content))
            } else if let error = review.errorMessage {
                ScrollView {
                    Text(error)
                        .font(.body)
                        .foregroundStyle(YPColor.risk)
                        .padding()
                }
            } else {
                ScrollView {
                    Text("暂无内容")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
        }
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

#Preview {
    DailyReviewView()
}
