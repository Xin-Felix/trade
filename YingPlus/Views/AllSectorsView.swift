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
                            SkeletonRow()
                        }
                    } else {
                        ForEach(Array(sectors.enumerated()), id: \.element.id) { index, sector in
                            NavigationLink {
                                SectorDetailView(sector: sector, isConcept: sectorType == .concept)
                            } label: {
                                SectorRow(
                                    index: index,
                                    name: sector.name,
                                    leadStock: sector.leadStock.map { "龙头: \($0)" },
                                    pctChange: sector.pctChange,
                                    netAmount: sector.netAmount
                                )
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
        .refreshable { await loadData(forceRefresh: true) }
        .task { await loadData() }
        .onChange(of: sectorType) { _, _ in
            Task { await loadData(forceRefresh: true) }
        }
    }

    private func loadData(forceRefresh: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let policy: CachePolicy = forceRefresh ? .skipCache : .default
            let resp = try await StockService.fetchSectorMoneyflow(sectorType: sectorType, limit: 50, policy: policy)
            sectors = resp.sectors
        } catch {
            if error is CancellationError { return }
            print("[AllSectors] 加载失败: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        AllSectorsView()
    }
}
