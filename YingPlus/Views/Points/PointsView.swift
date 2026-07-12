import SwiftUI

struct PointsView: View {
    @State private var balance: PointsBalance?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showComingSoonAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    balanceCard
                    actionsGrid

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding()
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("我的积分")
            .alert("敬请期待", isPresented: $showComingSoonAlert) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text("该功能正在开发中，即将上线。")
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
            .refreshable {
                await loadBalance()
            }
            .task {
                await loadBalance()
            }
        }
    }

    // MARK: - 余额卡片

    private var balanceCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "star.circle.fill")
                    .foregroundStyle(YPColor.warning)
                Text("当前积分")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("\(balance?.balance ?? 0)")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(YPColor.warning)

            HStack(spacing: 24) {
                balanceSummaryItem(title: "累计获得", value: balance?.totalEarned ?? 0, color: YPColor.success)
                balanceSummaryItem(title: "累计使用", value: balance?.totalUsed ?? 0, color: YPColor.up)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func balanceSummaryItem(title: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.headline)
                .foregroundStyle(color)
        }
    }

    // MARK: - 入口网格

    private var actionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            actionCard(icon: "plus.circle", title: "充值积分", color: YPColor.success) {
                showComingSoonAlert = true
            }

            NavigationLink {
                PointsHistoryView()
            } label: {
                actionCardContent(icon: "clock.arrow.circlepath", title: "积分记录", color: YPColor.accent)
            }
            .buttonStyle(.plain)

            NavigationLink {
                MembershipView(paymentInfo: nil)
            } label: {
                actionCardContent(icon: "crown", title: "会员特权", color: .orange)
            }
            .buttonStyle(.plain)

            actionCard(icon: "gift", title: "邀请奖励", color: YPColor.ai) {
                showComingSoonAlert = true
            }
        }
    }

    private func actionCard(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            actionCardContent(icon: icon, title: title, color: color)
        }
        .buttonStyle(.plain)
    }

    private func actionCardContent(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 数据加载

    private func loadBalance() async {
        isLoading = true
        errorMessage = nil
        do {
            balance = try await PointsService.fetchBalance()
        } catch {
            if error is CancellationError { return }
            errorMessage = error.localizedDescription
            print("[PointsView] 加载积分余额失败: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        PointsView()
    }
}
