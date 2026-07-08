import SwiftUI

struct MarketView: View {
    @State private var watchlist: [StockData] = []
    @State private var indices: [IndexItem] = [
        IndexItem(name: "上证指数", value: 3050.23, change: 0.68),
        IndexItem(name: "深证成指", value: 9876.54, change: 1.23),
        IndexItem(name: "创业板指", value: 1890.12, change: -0.45)
    ]
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchCode = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    searchSection
                    indexSection
                    watchlistSection
                }
                .padding()
            }
            .navigationTitle("行情")
            .refreshable {
                await loadWatchlist()
            }
            .task {
                await loadWatchlist()
            }
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("股票搜索")
                .font(.headline)

            HStack(spacing: 12) {
                TextField("输入股票代码，如 000001", text: $searchCode)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.asciiCapable)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                NavigationLink(value: searchCode.trimmingCharacters(in: .whitespaces)) {
                    Text("查询")
                        .fontWeight(.semibold)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(searchCode.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationDestination(for: String.self) { code in
            StockDetailView(code: code, name: "")
        }
    }

    private var indexSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("大盘指数")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(indices) { index in
                    VStack(spacing: 4) {
                        Text(index.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f", index.value))
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(String(format: "%.2f%%", index.change))
                            .font(.caption)
                            .foregroundStyle(index.change >= 0 ? .red : .green)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("自选股")
                    .font(.headline)
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                Button("刷新") {
                    Task { await loadWatchlist() }
                }
                .font(.caption)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.subheadline)
            }

            LazyVStack(spacing: 8) {
                ForEach(watchlist) { stock in
                    NavigationLink(value: stock) {
                        StockRow(stock: stock)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationDestination(for: StockData.self) { stock in
            StockDetailView(code: stock.code, name: stock.name)
        }
    }

    private func loadWatchlist() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            watchlist = try await StockService.fetchWatchlist()
        } catch APIError.unauthorized {
            errorMessage = "未登录，无法获取自选股"
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
        }
    }
}

struct StockRow: View {
    let stock: StockData

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.name)
                    .font(.headline)
                Text(stock.code)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f", stock.price))
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(String(format: "%.2f%%", stock.changePercent))
                    .font(.caption)
                    .foregroundStyle(stock.changePercent >= 0 ? .red : .green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background((stock.changePercent >= 0 ? Color.red : Color.green).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct IndexItem: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let change: Double
}

#Preview {
    MarketView()
}
