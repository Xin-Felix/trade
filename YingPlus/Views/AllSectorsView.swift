import SwiftUI

/// 全部板块资金流排行页
struct AllSectorsView: View {
    @State private var sectors: [SectorMoneyflowData] = []
    @State private var isLoading = false
    @State private var sectorType: SectorMoneyflowType = .industry

    var body: some View {
        VStack(spacing: 0) {
            // 行业/概念切换
            Picker("板块类型", selection: $sectorType) {
                Text("行业").tag(SectorMoneyflowType.industry)
                Text("概念").tag(SectorMoneyflowType.concept)
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                LazyVStack(spacing: 8) {
                    if isLoading && sectors.isEmpty {
                        ForEach(0..<10) { _ in
                            skeletonRow
                        }
                    } else {
                        ForEach(Array(sectors.enumerated()), id: \.element.id) { index, sector in
                            NavigationLink {
                                SectorDetailView(sector: sector)
                            } label: {
                                sectorRow(index: index, sector: sector)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("板块排行")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await loadData() }
        .task { await loadData() }
        .onChange(of: sectorType) { _, _ in
            Task { await loadData() }
        }
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let resp = try await StockService.fetchSectorMoneyflow(sectorType: sectorType, limit: 50)
            sectors = resp.sectors
        } catch {
            print("[AllSectors] 加载失败: \(error)")
        }
    }

    private func sectorRow(index: Int, sector: SectorMoneyflowData) -> some View {
        HStack(spacing: 10) {
            Text("\(index + 1)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(index < 3 ? YPColor.warning : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(sector.name ?? "--")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let lead = sector.leadStock {
                    Text("龙头: \(lead)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let pct = sector.pctChange {
                Text(String(format: "%+.2f%%", pct))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(pct >= 0 ? YPColor.up : YPColor.down)
                    .frame(width: 60, alignment: .trailing)
            }

            if let net = sector.netAmount {
                Text(String(format: "%.0f亿", net))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(net >= 0 ? YPColor.up : YPColor.down)
                    .frame(width: 45, alignment: .trailing)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.quaternary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var skeletonRow: some View {
        HStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 70, height: 14)
            Spacer()
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 50, height: 14)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack {
        AllSectorsView()
    }
}
