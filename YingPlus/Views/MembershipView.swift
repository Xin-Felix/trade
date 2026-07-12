import SwiftUI

struct MembershipView: View {
    let paymentInfo: PaymentRequiredInfo?
    @Environment(\.dismiss) private var dismiss
    @State private var tiers: [MembershipTier] = []
    @State private var status: MembershipStatus?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let info = paymentInfo {
                        paymentHintCard(info: info)
                    }

                    if let status = status {
                        currentStatusCard(status: status)
                    }

                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if tiers.isEmpty {
                        Text("暂无会员套餐")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("会员套餐")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(tiers.filter { $0.enabled == 1 }) { tier in
                                tierCard(tier: tier)
                            }
                        }
                    }

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("会员中心")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }

    private func paymentHintCard(info: PaymentRequiredInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.orange)
                Text("功能受限")
                    .font(.headline)
                Spacer()
            }

            Text(info.reason)
                .font(.subheadline)
                .foregroundStyle(.primary)

            HStack {
                Label("当前积分: \(info.balance)", systemImage: "bolt.horizontal.circle")
                    .font(.caption)
                Spacer()
                if info.requiredPoints > 0 {
                    Label("需要: \(info.requiredPoints)", systemImage: "bolt.horizontal.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func currentStatusCard(status: MembershipStatus) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: status.active ? "crown.fill" : "crown")
                    .foregroundStyle(status.active ? .orange : .secondary)
                Text(status.active ? "当前会员" : "暂无会员")
                    .font(.headline)
                Spacer()
            }

            if status.active, let tierCode = status.tierCode {
                Text("套餐: \(tierCode)")
                    .font(.subheadline)
                if let expiresAt = status.expiresAt {
                    Text("到期: \(expiresAt)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("积分余额: \(status.balance)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func tierCard(tier: MembershipTier) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.name)
                        .font(.headline)
                    if let description = tier.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Text("¥\(tier.priceYuan)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 12) {
                Label("\(tier.durationDays) 天", systemImage: "calendar")
                if tier.monthlyPointsGrant > 0 {
                    Label("每月 \(tier.monthlyPointsGrant) 积分", systemImage: "bolt.horizontal")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !tier.features.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(tier.features, id: \.self) { feature in
                        Text(feature == "*" ? "全部功能" : feature)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.1))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }
            }

            Button {
                // TODO: 接入支付
                showPaymentAlert(tier: tier)
            } label: {
                Text("开通")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let tiersTask = MembershipService.fetchTiers()
            async let statusTask = MembershipService.fetchStatus()
            tiers = try await tiersTask
            status = try await statusTask
        } catch {
            if error is CancellationError { return }
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func showPaymentAlert(tier: MembershipTier) {
        // 临时占位：实际应调用支付 SDK
        print("开通会员: \(tier.name) - ¥\(tier.priceYuan)")
    }
}

// MARK: - 简单流式布局

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x)
            }
            self.size.height = y + rowHeight
        }
    }
}

#Preview {
    MembershipView(paymentInfo: nil)
}
