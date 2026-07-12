import SwiftUI

// MARK: - 国际市场指数卡片

struct GlobalMarketCard: View {
    let indices: [IndexItem]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if indices.isEmpty {
                    ForEach(0..<4) { _ in
                        placeholderCard
                    }
                } else {
                    ForEach(indices) { index in
                        indexCard(index)
                    }
                }
            }
            .padding(.horizontal, 1)
        }
    }

    private func indexCard(_ index: IndexItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(index.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(String(format: "%.2f", index.value))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            HStack(spacing: 4) {
                Image(systemName: index.change >= 0 ? "arrow.up" : "arrow.down")
                    .font(.caption2)
                Text(String(format: "%+.2f%%", index.change))
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(index.change >= 0 ? YPColor.up : YPColor.down)
        }
        .frame(width: 120, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var placeholderCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 60, height: 12)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 80, height: 16)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 50, height: 12)
        }
        .frame(width: 120, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    GlobalMarketCard(indices: [
        IndexItem(name: "道琼斯", value: 34500.2, change: 0.35, tsCode: "DJI"),
        IndexItem(name: "纳斯达克", value: 13800.5, change: -0.12, tsCode: "IXIC"),
        IndexItem(name: "恒生指数", value: 17500.3, change: 1.05, tsCode: "HSI"),
    ])
    .padding()
}
