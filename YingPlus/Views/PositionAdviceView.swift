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

/// AI 仓位建议页面
struct PositionAdviceView: View {
    @State private var todayAdvice: AiPositionAdviceItem?
    @State private var advices: [AiPositionAdviceItem] = []
    @State private var isLoading = false
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var selectedAdvice: AiPositionAdviceItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    todayAdviceSection
                    historySection
                }
                .padding()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("AI 仓位建议")
            .refreshable {
                await loadData()
            }
            .task {
                await loadData()
            }
            .sheet(item: $selectedAdvice) { advice in
                PositionAdviceDetailView(advice: advice)
            }
        }
    }

    // MARK: - 今日仓位建议

    private var todayAdviceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeaderView(icon: "chart.pie", title: "今日仓位建议", color: YPColor.ai)
                Spacer()
                if isLoading || isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if let advice = todayAdvice {
                if advice.status == "success", let summary = effectiveSummary(for: advice) {
                    adviceContentCard(summary: summary) {
                        selectedAdvice = advice
                    }
                } else if advice.status == "failed" {
                    failedCard(message: advice.errorMessage ?? "生成失败") {
                        Task { await generateTodayAdvice() }
                    }
                } else {
                    pendingCard(message: "仓位建议正在生成中，请稍后再试")
                }
            } else if let error = errorMessage {
                failedCard(message: error) {
                    Task { await generateTodayAdvice() }
                }
            } else {
                emptyCard(message: "今日仓位建议尚未生成") {
                    Task { await generateTodayAdvice() }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 历史仓位建议

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "clock.arrow.circlepath", title: "历史建议", color: YPColor.info)

            if advices.isEmpty {
                emptyCard(message: "暂无历史仓位建议", action: nil)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(advices) { advice in
                        historyRow(advice: advice)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func historyRow(advice: AiPositionAdviceItem) -> some View {
        Button {
            selectedAdvice = advice
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(advice.reportDate ?? "未知日期")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 6) {
                        statusBadge(status: advice.status)

                        if let preview = effectiveSummary(for: advice) {
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

    private func adviceContentCard(summary: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(summary)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(4)

            Button(action: action) {
                HStack {
                    Spacer()
                    Text("查看完整建议")
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

    private func emptyCard(message: String, action: (() -> Void)?) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "chart.pie")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let action {
                    Button(action: { Task { await generateTodayAdvice() } }) {
                        Label("立即生成", systemImage: "sparkles")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(YPColor.aiGradient)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isGenerating)
                }
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

    private func failedCard(message: String, action: @escaping () -> Void) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(YPColor.risk)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: action) {
                    Label("重新生成", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(YPColor.risk.opacity(0.1))
                        .foregroundStyle(YPColor.risk)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isGenerating)
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

    // MARK: - 数据加载

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            todayAdvice = try await AiPositionAdviceService.fetchTodayAdvice()
        } catch APIError.httpError(let statusCode, _) where statusCode == 404 {
            todayAdvice = nil
        } catch APIError.paymentRequired {
            errorMessage = "该功能需要会员或积分权限"
        } catch APIError.unauthorized {
            errorMessage = "登录已过期"
        } catch is CancellationError {
            // 忽略
        } catch {
            if errorMessage == nil {
                errorMessage = "加载失败：\(error.localizedDescription)"
            }
        }

        do {
            let history = try await AiPositionAdviceService.fetchAdvices(page: 1, pageSize: 20)
            advices = history.list
        } catch APIError.httpError(let statusCode, _) where statusCode == 404 {
            advices = []
        } catch APIError.paymentRequired {
            // 已由全局通知
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

    private func generateTodayAdvice() async {
        isGenerating = true
        defer { isGenerating = false }

        do {
            _ = try await AiPositionAdviceService.generateTodayAdvice()
            await loadData()
        } catch APIError.paymentRequired {
            errorMessage = "该功能需要会员或积分权限"
        } catch APIError.unauthorized {
            errorMessage = "登录已过期"
        } catch {
            errorMessage = "生成失败：\(error.localizedDescription)"
        }
    }

    // MARK: - 摘要显示

    private func effectiveSummary(for advice: AiPositionAdviceItem) -> String? {
        if let summary = advice.summary, !summary.isEmpty {
            return summary
        }
        guard let content = advice.content, !content.isEmpty else { return nil }
        let endIndex = content.index(content.startIndex, offsetBy: min(100, content.count), limitedBy: content.endIndex) ?? content.endIndex
        return String(content[..<endIndex])
    }
}

// MARK: - 仓位建议详情页

struct PositionAdviceDetailView: View {
    let advice: AiPositionAdviceItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                headerView
                    .padding()
                Divider()
                markdownContentView
            }
            .navigationTitle("建议详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        if advice.status == "success", let content = advice.content {
                            ReportShareToolbarButton(
                                type: .advice,
                                date: advice.reportDate ?? "未知日期",
                                status: advice.status,
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
                Text(advice.reportDate ?? "未知日期")
                    .font(.headline)

                HStack(spacing: 8) {
                    let (label, color) = statusInfo(advice.status)
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
            if advice.status == "success", let content = advice.content {
                H5WebView(htmlString: MarkdownHTMLRenderer.render(content))
            } else if let error = advice.errorMessage {
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
    PositionAdviceView()
}
