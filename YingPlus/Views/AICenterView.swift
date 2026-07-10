import SwiftUI

struct AICenterView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 顶部品牌标识
                    aiHeaderBanner

                    VStack(spacing: 14) {
                        aiMarketAnalysisSection
                        aiStockAnalysisSection
                        aiAnnouncementSection
                        aiNewsSummarySection
                        aiFinancialReportSection
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("AI 中心")
        }
    }

    // MARK: - 顶部 Banner

    private var aiHeaderBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("AI 智能分析")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text("多维度数据驱动，辅助投资决策")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()
        }
        .padding()
        .background(YPColor.brandGradient)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - AI 市场分析

    private var aiMarketAnalysisSection: some View {
        aiFeatureCard(
            icon: "chart.bar.doc.horizontal",
            title: "AI 市场分析",
            description: "基于多维度数据的智能市场研判",
            color: YPColor.ai,
            tags: ["市场情绪", "趋势判断", "风险评估"]
        )
    }

    // MARK: - AI 个股分析

    private var aiStockAnalysisSection: some View {
        aiFeatureCard(
            icon: "magnifyingglass.circle",
            title: "AI 个股分析",
            description: "深度解读个股基本面、技术面与资金面",
            color: YPColor.accent,
            tags: ["基本面", "技术面", "资金流"]
        )
    }

    // MARK: - AI 公告解读

    private var aiAnnouncementSection: some View {
        aiFeatureCard(
            icon: "doc.richtext",
            title: "AI 公告解读",
            description: "快速提取公告要点，解读利好利空",
            color: YPColor.info,
            tags: ["要点提取", "影响评估", "关联分析"]
        )
    }

    // MARK: - AI 新闻总结

    private var aiNewsSummarySection: some View {
        aiFeatureCard(
            icon: "newspaper",
            title: "AI 新闻总结",
            description: "聚合市场新闻，提炼关键信息",
            color: YPColor.brandBlue,
            tags: ["热点聚合", "情绪分析", "事件驱动"]
        )
    }

    // MARK: - AI 财报分析

    private var aiFinancialReportSection: some View {
        aiFeatureCard(
            icon: "tablecells",
            title: "AI 财报分析",
            description: "自动解析财务报表，识别关键财务指标变化",
            color: YPColor.success,
            tags: ["营收利润", "现金流", "成长性"]
        )
    }

    // MARK: - 通用 AI 功能卡片

    private func aiFeatureCard(icon: String, title: String, description: String, color: Color, tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.quaternary)
            }

            HStack(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .foregroundStyle(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(color.opacity(0.08))
                        .clipShape(Capsule())
                }

                Spacer()

                Label("即将上线", systemImage: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    AICenterView()
}
