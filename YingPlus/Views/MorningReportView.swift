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

/// AI 晨报页面
struct MorningReportView: View {
    @State private var todayReport: AiMorningReportItem?
    @State private var reports: [AiMorningReportItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedReport: AiMorningReportItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    todayReportSection
                    historySection
                }
                .padding()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("AI 晨报")
            .refreshable {
                await loadData()
            }
            .task {
                await loadData()
            }
            .sheet(item: $selectedReport) { report in
                MorningReportDetailView(report: report)
            }
        }
    }

    // MARK: - 今日晨报

    private var todayReportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeaderView(icon: "sunrise", title: "今日晨报", color: YPColor.ai)
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if let report = todayReport {
                if report.status == "success", let summary = effectiveSummary(for: report) {
                    reportContentCard(summary: summary) {
                        selectedReport = report
                    }
                } else if report.status == "failed" {
                    failedCard(message: report.errorMessage ?? "生成失败")
                } else {
                    pendingCard(message: "晨报正在生成中，请稍后再试")
                }
            } else if let error = errorMessage {
                failedCard(message: error)
            } else {
                emptyCard(message: "今日晨报尚未生成")
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 历史晨报

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(icon: "clock.arrow.circlepath", title: "历史晨报", color: YPColor.info)

            if reports.isEmpty {
                emptyCard(message: "暂无历史晨报")
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(reports) { report in
                        historyRow(report: report)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func historyRow(report: AiMorningReportItem) -> some View {
        Button {
            selectedReport = report
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.reportDate ?? "未知日期")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 6) {
                        statusBadge(status: report.status)

                        if let preview = effectiveSummary(for: report) {
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

    private func reportContentCard(summary: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(summary)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(4)

            Button(action: action) {
                HStack {
                    Spacer()
                    Text("查看完整晨报")
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
                Image(systemName: "newspaper")
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

    // MARK: - 数据加载

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            todayReport = try await AiMorningReportService.fetchTodayReport()
        } catch APIError.httpError(let statusCode, _) where statusCode == 404 {
            todayReport = nil
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
            let history = try await AiMorningReportService.fetchReports(page: 1, pageSize: 20)
            reports = history.list
        } catch APIError.httpError(let statusCode, _) where statusCode == 404 {
            reports = []
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

    // MARK: - 摘要显示

    private func effectiveSummary(for report: AiMorningReportItem) -> String? {
        if let summary = report.summary, !summary.isEmpty {
            return summary
        }
        guard let content = report.content, !content.isEmpty else { return nil }
        let endIndex = content.index(content.startIndex, offsetBy: min(100, content.count), limitedBy: content.endIndex) ?? content.endIndex
        return String(content[..<endIndex])
    }
}

// MARK: - 晨报详情页

struct MorningReportDetailView: View {
    let report: AiMorningReportItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                headerView
                    .padding()
                Divider()
                markdownContentView
            }
            .navigationTitle("晨报详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        if report.status == "success", let content = report.content {
                            ReportShareToolbarButton(
                                type: .morning,
                                date: report.reportDate ?? "未知日期",
                                status: report.status,
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
                Text(report.reportDate ?? "未知日期")
                    .font(.headline)

                HStack(spacing: 8) {
                    let (label, color) = statusInfo(report.status)
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
            if report.status == "success", let content = report.content {
                H5WebView(htmlString: MarkdownHTMLRenderer.render(content))
            } else if let error = report.errorMessage {
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
    MorningReportView()
}
