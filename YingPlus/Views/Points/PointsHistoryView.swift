import SwiftUI

struct PointsHistoryView: View {
    @State private var records: [PointsRecord] = []
    @State private var total = 0
    @State private var currentPage = 1
    @State private var pageSize = 20
    @State private var isLoading = false
    @State private var loadError: Error?
    @State private var hasMoreData = true

    var body: some View {
        NavigationStack {
            List {
                ForEach(records) { record in
                    recordRow(record)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .onAppear {
                            if record.id == records.last?.id {
                                Task { await loadMoreRecords() }
                            }
                        }
                }

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                } else if !hasMoreData && !records.isEmpty {
                    Text("没有更多记录了")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .navigationTitle("积分记录")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await reloadRecords()
            }
            .task {
                await reloadRecords()
            }
            .overlay {
                if records.isEmpty && !isLoading {
                    emptyState
                }
            }
        }
    }

    // MARK: - 单条记录

    private func recordRow(_ record: PointsRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: record.type.isPositive ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.title3)
                .foregroundStyle(record.type.isPositive ? YPColor.success : YPColor.up)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.description ?? record.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(record.createdAt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(record.type.isPositive ? "+" : "-")\(record.amount)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(record.type.isPositive ? YPColor.success : YPColor.up)
                Text("余额: \(record.balanceAfter)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 空状态

    private var emptyState: some View {
        VStack(spacing: 12) {
            if let error = loadError {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(YPColor.warning)
                Text("加载失败")
                    .font(.headline)
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "doc.text")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("暂无积分记录")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // MARK: - 数据加载

    private func reloadRecords() async {
        currentPage = 1
        records = []
        hasMoreData = true
        await loadRecords()
    }

    private func loadMoreRecords() async {
        guard hasMoreData && !isLoading else { return }
        currentPage += 1
        await loadRecords()
    }

    private func loadRecords() async {
        isLoading = true
        loadError = nil
        do {
            let data = try await PointsService.fetchRecords(page: currentPage, pageSize: pageSize)
            if currentPage == 1 {
                records = data.list
            } else {
                records.append(contentsOf: data.list)
            }
            total = data.total
            hasMoreData = records.count < total
        } catch {
            if error is CancellationError { return }
            loadError = error
            print("[PointsHistoryView] 加载积分记录失败: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        PointsHistoryView()
    }
}
