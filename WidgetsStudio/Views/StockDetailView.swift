import SwiftUI

struct StockDetailView: View {
    let code: String
    let name: String

    @State private var selectedPeriod: KlinePeriod = .day
    @State private var klines: [KlineData] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerView
                periodPicker
                chartCard
                infoCard
            }
            .padding()
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadKlines()
        }
        .onChange(of: selectedPeriod) { _, _ in
            Task {
                await loadKlines()
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            Text(code)
                .font(.title2)
                .fontWeight(.bold)
            Text(name)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var periodPicker: some View {
        Picker("周期", selection: $selectedPeriod) {
            ForEach(KlinePeriod.allCases, id: \.self) { period in
                Text(period.title).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(selectedPeriod.title) 走势图")
                .font(.headline)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 240)
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, minHeight: 240)
            } else {
                KLineChartView(data: klines)
                    .frame(height: 240)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("数据说明")
                .font(.headline)

            HStack {
                Label("红色 = 上涨", systemImage: "arrow.up")
                    .foregroundStyle(.red)
                Spacer()
                Label("绿色 = 下跌", systemImage: "arrow.down")
                    .foregroundStyle(.green)
            }

            Text("周/月/年 K 线由日线聚合生成")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func loadKlines() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let limit = klineLimit(for: selectedPeriod)
            klines = try await StockService.fetchKlines(code: code, period: selectedPeriod, limit: limit)
        } catch APIError.unauthorized {
            errorMessage = "未登录，请先登录"
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
        }
    }

    private func klineLimit(for period: KlinePeriod) -> Int {
        switch period {
        case .day: return 180
        case .week: return 104
        case .month: return 60
        case .year: return 10
        }
    }
}

#Preview {
    NavigationStack {
        StockDetailView(code: "000001", name: "平安银行")
    }
}
