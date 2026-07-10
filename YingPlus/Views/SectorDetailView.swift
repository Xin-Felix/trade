import SwiftUI

/// 板块详情页 — 展示板块信息和成分股列表
struct SectorDetailView: View {
    let sector: SectorMoneyflowData

    @State private var members: [SectorMemberItem] = []
    @State private var isLoading = false
    @State private var selectedStock: SectorMemberItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                sectorInfoCard
                memberListSection
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle(sector.name ?? "板块详情")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await loadMembers() }
        .task { await loadMembers() }
        .navigationDestination(item: $selectedStock) { member in
            StockDetailView(code: member.conCode, name: member.conName ?? member.conCode)
        }
    }

    // MARK: - 板块信息卡

    private var sectorInfoCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("涨跌幅")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let pct = sector.pctChange {
                        Text(String(format: "%+.2f%%", pct))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(pct >= 0 ? YPColor.up : YPColor.down)
                    } else {
                        Text("--")
                            .font(.title3)
                            .foregroundStyle(.tertiary)
                    }
                }

                VStack(spacing: 4) {
                    Text("净流入")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let net = sector.netAmount {
                        Text(String(format: "%.1f亿", net))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(net >= 0 ? YPColor.up : YPColor.down)
                    } else {
                        Text("--")
                            .font(.title3)
                            .foregroundStyle(.tertiary)
                    }
                }

                VStack(spacing: 4) {
                    Text("成分股")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let num = sector.companyNum {
                        Text("\(num)只")
                            .font(.title3)
                            .fontWeight(.bold)
                    } else {
                        Text("--")
                            .font(.title3)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            if let lead = sector.leadStock, let pctStock = sector.pctChangeStock {
                HStack(spacing: 6) {
                    Text("龙头股:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(lead)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(String(format: "%+.2f%%", pctStock))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(pctStock >= 0 ? YPColor.up : YPColor.down)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 成分股列表

    private var memberListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("成分股")
                    .font(.headline)
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
                Text("\(members.count)只")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if members.isEmpty && !isLoading {
                PlaceholderCard(icon: "list.bullet", description: "暂无成分股数据", color: .secondary)
            } else {
                ForEach(members) { member in
                    Button {
                        selectedStock = member
                    } label: {
                        memberRow(member)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func memberRow(_ member: SectorMemberItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(member.conName ?? "--")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text(member.conCode)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - 数据加载

    private func loadMembers() async {
        isLoading = true
        defer { isLoading = false }
        do {
            members = try await MarketService.fetchSectorMembers(code: sector.tsCode)
        } catch {
            print("[SectorDetail] 成分股加载失败: \(error)")
        }
    }
}

// Make SectorMemberItem conform to Hashable for navigationDestination
extension SectorMemberItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(conCode)
    }

    static func == (lhs: SectorMemberItem, rhs: SectorMemberItem) -> Bool {
        lhs.conCode == rhs.conCode
    }
}


