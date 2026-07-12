import SwiftUI

/// 板块详情页 — 展示板块信息和成分股列表
struct SectorDetailView: View {
    let sector: SectorMoneyflowData
    let isConcept: Bool

    init(sector: SectorMoneyflowData, isConcept: Bool = false) {
        self.sector = sector
        self.isConcept = isConcept
    }

    @State private var sectorInfo: SectorMoneyflowData?
    @State private var isLoadingInfo = false
    @State private var infoError: Error?

    private var displaySector: SectorMoneyflowData {
        sectorInfo ?? sector
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                sectorInfoCard
                descriptionCard
                SectorMemberListView(sectorCode: sector.tsCode, isConcept: isConcept)
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle(displaySector.name ?? "板块详情")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadSectorInfo()
        }
    }

    private func loadSectorInfo() async {
        guard sectorInfo == nil else { return }
        isLoadingInfo = true
        defer { isLoadingInfo = false }

        do {
            let sectorType: SectorMoneyflowType = isConcept ? .concept : .industry
            let response = try await StockService.fetchSectorMoneyflow(
                sectorType: sectorType,
                tradeDate: sector.tradeDate.isEmpty ? nil : sector.tradeDate,
                limit: 200,
                policy: .default
            )
            if let matched = response.sectors.first(where: { $0.tsCode == sector.tsCode }) {
                sectorInfo = matched
            }
        } catch {
            if error is CancellationError { return }
            infoError = error
            print("[SectorDetail] 板块信息加载失败: \(error.localizedDescription)")
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
                    if let pct = displaySector.pctChange {
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
                    if let net = displaySector.netAmount {
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
                    if let num = displaySector.companyNum {
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

            if let lead = displaySector.leadStock, let pctStock = displaySector.pctChangeStock {
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

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("简介")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
            }

            Text("暂无简介")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        SectorDetailView(
            sector: SectorMoneyflowData(
                tsCode: "885431",
                tradeDate: "20260710",
                name: "半导体",
                leadStock: "中芯国际",
                closePrice: nil,
                pctChange: 2.35,
                companyNum: 128,
                pctChangeStock: 5.67,
                netBuyAmount: nil,
                netSellAmount: nil,
                netAmount: 12.5
            ),
            isConcept: false
        )
    }
}
