import SwiftUI

// MARK: - 盈多多品牌色系

enum YPColor {
    // 品牌主色
    static let brandBlue = Color(red: 0.2, green: 0.47, blue: 0.96)
    static let brandPurple = Color(red: 0.55, green: 0.35, blue: 0.95)
    static let brandCyan = Color(red: 0.2, green: 0.78, blue: 0.85)

    // 设计文档语义色
    static let hot = Color(red: 0.96, green: 0.62, blue: 0.04)          // #F59E0B
    static let international = Color(red: 0.08, green: 0.72, blue: 0.65) // #14B8A6
    static let risk = Color(red: 0.94, green: 0.27, blue: 0.27)          // #EF4444

    // 功能色
    static let market = brandBlue
    static let accent = brandBlue
    static let ai = brandPurple
    static let info = brandCyan

    // 涨跌色
    static let up = Color(red: 0.9, green: 0.2, blue: 0.2)
    static let down = Color(red: 0.15, green: 0.7, blue: 0.35)

    // 辅助色
    static let warning = Color(red: 0.95, green: 0.6, blue: 0.15)
    static let success = Color(red: 0.2, green: 0.75, blue: 0.45)

    // 品牌渐变
    static let brandGradient = LinearGradient(
        colors: [brandPurple, brandBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let aiGradient = LinearGradient(
        colors: [brandPurple, brandCyan],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - UIKit 桥接

extension YPColor {
    static let uiUp = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1)
    static let uiDown = UIColor(red: 0.15, green: 0.7, blue: 0.35, alpha: 1)
    static let uiAccent = UIColor(red: 0.2, green: 0.47, blue: 0.96, alpha: 1)
}

// MARK: - 通用 Section Header

struct SectionHeaderView: View {
    let icon: String
    let title: String
    let color: Color
    var trailing: String? = nil

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - 通用占位卡片

struct PlaceholderCard: View {
    let icon: String
    let title: String
    let description: String
    var color: Color = .secondary

    init(icon: String, title: String = "即将上线", description: String, color: Color = .secondary) {
        self.icon = icon
        self.title = title
        self.description = description
        self.color = color
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color.opacity(0.6))
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
