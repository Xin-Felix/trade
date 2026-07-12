import SwiftUI

// MARK: - 市场页功能菜单行

struct MarketMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    VStack(spacing: 12) {
        MarketMenuRow(icon: "trophy.circle.fill", title: "龙虎榜", subtitle: "异动个股与机构席位", color: YPColor.warning)
        MarketMenuRow(icon: "arrow.up.circle.fill", title: "涨停梯队", subtitle: nil, color: YPColor.up)
    }
    .padding()
}
