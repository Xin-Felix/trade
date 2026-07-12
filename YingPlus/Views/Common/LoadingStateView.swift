import SwiftUI

/// 通用页面状态视图：加载中、空状态、错误重试
struct LoadingStateView: View {
    let isLoading: Bool
    let isEmpty: Bool
    let error: Error?
    let emptyTitle: String
    let emptyDescription: String
    let emptyIcon: String
    let color: Color
    let onRetry: (() -> Void)?

    init(
        isLoading: Bool,
        isEmpty: Bool,
        error: Error? = nil,
        emptyTitle: String = "暂无数据",
        emptyDescription: String = "",
        emptyIcon: String = "doc.text.magnifyingglass",
        color: Color = .secondary,
        onRetry: (() -> Void)? = nil
    ) {
        self.isLoading = isLoading
        self.isEmpty = isEmpty
        self.error = error
        self.emptyTitle = emptyTitle
        self.emptyDescription = emptyDescription
        self.emptyIcon = emptyIcon
        self.color = color
        self.onRetry = onRetry
    }

    var body: some View {
        if isLoading && isEmpty {
            ProgressView()
                .scaleEffect(1.2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 60)
        } else if let error = error {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(YPColor.warning.opacity(0.8))
                Text("数据加载失败")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                if let onRetry {
                    Button("重试") {
                        onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .padding(.horizontal)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if isEmpty {
            PlaceholderCard(
                icon: emptyIcon,
                title: emptyTitle,
                description: emptyDescription,
                color: color
            )
        } else {
            EmptyView()
        }
    }
}

/// 通用列表骨架行
struct SkeletonRow: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 80, height: 14)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 60, height: 10)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 70, height: 16)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// 通用卡片骨架
struct SkeletonCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.tertiarySystemFill))
            .frame(height: 120)
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingStateView(
            isLoading: true,
            isEmpty: true
        )
        LoadingStateView(
            isLoading: false,
            isEmpty: true,
            emptyTitle: "暂无数据",
            emptyDescription: "下拉刷新试试"
        )
        LoadingStateView(
            isLoading: false,
            isEmpty: true,
            error: NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "网络超时"]),
            onRetry: {}
        )
    }
    .padding()
}
