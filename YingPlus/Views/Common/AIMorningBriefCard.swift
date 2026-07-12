import SwiftUI

// MARK: - AI 晨报卡片

struct AIMorningBriefCard: View {
    let summary: String?
    let reportDate: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "brain")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    Text("AI 晨报")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                Spacer()

                if let dateLabel = formattedDateLabel {
                    Text(dateLabel)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.15))
                        .clipShape(Capsule())
                }

                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }

            if let summary, !summary.isEmpty {
                Text(summary)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.95))
                    .lineSpacing(4)
                    .lineLimit(4)
            } else {
                placeholder
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(YPColor.aiGradient)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var formattedDateLabel: String? {
        guard let reportDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())
        if reportDate == todayString {
            return "今日"
        }
        return reportDate
    }

    private var placeholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(.white.opacity(0.2))
                .frame(height: 14)
            RoundedRectangle(cornerRadius: 4)
                .fill(.white.opacity(0.2))
                .frame(height: 14)
            RoundedRectangle(cornerRadius: 4)
                .fill(.white.opacity(0.2))
                .frame(width: 200, height: 14)
        }
    }
}

#Preview {
    VStack {
        AIMorningBriefCard(summary: "今日 A 股小幅高开，科技成长板块延续强势，北向资金持续净流入。建议关注半导体、AI 算力方向，同时注意高位题材分化风险。", reportDate: "今日")
        AIMorningBriefCard(summary: nil, reportDate: nil)
    }
    .padding()
}
