import SwiftUI

/// 板块成分股列表组件 — 支持分页、排序、涨跌幅展示
struct SectorMemberListView: View {
    let sectorCode: String
    let isConcept: Bool

    init(sectorCode: String, isConcept: Bool = false) {
        self.sectorCode = sectorCode
        self.isConcept = isConcept
    }

    @State private var members: [SectorMemberItem] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var loadError: Error?
    @State private var selectedStock: SectorMemberItem?
    @State private var currentPage = 1
    @State private var hasMoreData = true
    @State private var sortOption: MemberSortOption = .pctChangeDesc
    @State private var selectedBoard: MemberBoardFilter = .all

    private let pageSize = 20

    private var isTHSIndex: Bool {
        sectorCode.hasSuffix(".TI")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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

            if !isConcept {
                boardFilterBar
            }

            if !members.isEmpty || isLoading {
                memberListHeader
            }

            if members.isEmpty && !isLoading {
                if let error = loadError {
                    errorPlaceholder(error)
                } else {
                    PlaceholderCard(
                        icon: "list.bullet",
                        title: "暂无数据",
                        description: "暂无成分股数据",
                        color: .secondary
                    )
                }
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                        Button {
                            selectedStock = member
                        } label: {
                            memberRow(member)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            if index == members.count - 1 && hasMoreData && !isLoadingMore {
                                Task { await loadMoreMembers() }
                            }
                        }
                    }

                    if isLoadingMore {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }
        }
        .refreshable { await reloadMembers() }
        .task { await loadMembers() }
        .navigationDestination(item: $selectedStock) { member in
            StockDetailView(code: member.conCode, name: member.conName ?? member.conCode)
        }
    }

    private var boardFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MemberBoardFilter.allCases) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedBoard = filter
                        }
                        Task { await reloadMembers() }
                    } label: {
                        Text(filter.title)
                            .font(.caption)
                            .fontWeight(selectedBoard == filter ? .semibold : .regular)
                            .foregroundStyle(selectedBoard == filter ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedBoard == filter ? YPColor.accent : Color(.tertiarySystemFill))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var memberListHeader: some View {
        HStack(spacing: 10) {
            Button {
                toggleNameSort()
            } label: {
                HStack(spacing: 2) {
                    Text("股票")
                        .font(.caption)
                    Image(systemName: nameSortIcon)
                        .font(.caption2)
                }
                .foregroundStyle(sortOption.isNameSort ? YPColor.accent : .secondary)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                togglePctChangeSort()
            } label: {
                HStack(spacing: 2) {
                    Text("涨幅")
                        .font(.caption)
                    Image(systemName: pctChangeSortIcon)
                        .font(.caption2)
                }
                .foregroundStyle(sortOption.isPctChangeSort ? YPColor.accent : .secondary)
            }
            .buttonStyle(.plain)
            .frame(width: 62, alignment: .trailing)

            Color.clear
                .frame(width: 12)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func memberRow(_ member: SectorMemberItem) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(member.conName ?? "--")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(member.conCode)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let pct = member.pctChange {
                Text(String(format: "%+.2f%%", pct))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(pct >= 0 ? YPColor.up : YPColor.down)
                    .frame(width: 62, alignment: .trailing)
            } else {
                Text("--")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(width: 62, alignment: .trailing)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func errorPlaceholder(_ error: Error) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(YPColor.warning.opacity(0.8))
            Text("加载失败")
                .font(.subheadline)
                .fontWeight(.medium)
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("重试") {
                Task { await reloadMembers() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - 数据加载

    private func reloadMembers() async {
        currentPage = 1
        hasMoreData = true
        await loadMembers(forceRefresh: true)
    }

    private func loadMembers(forceRefresh: Bool = false) async {
        guard !isLoading else { return }
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        currentPage = 1
        do {
            let policy: CachePolicy = forceRefresh ? .skipCache : .default
            let newMembers: [SectorMemberItem]
            if isConcept && !isTHSIndex {
                let conceptMembers = try await MarketService.fetchConceptMembers(
                    conceptId: sectorCode,
                    page: currentPage,
                    pageSize: pageSize,
                    policy: policy
                )
                // 概念成分股接口若为空或不存在，回退到同花顺指数成分股接口
                newMembers = conceptMembers.isEmpty
                    ? try await MarketService.fetchSectorMembers(
                        code: sectorCode,
                        page: currentPage,
                        pageSize: pageSize,
                        sortBy: sortOption.sortBy,
                        sortOrder: sortOption.sortOrder,
                        board: selectedBoard.rawValue,
                        policy: policy
                    )
                    : conceptMembers
            } else {
                newMembers = try await MarketService.fetchSectorMembers(
                    code: sectorCode,
                    page: currentPage,
                    pageSize: pageSize,
                    sortBy: sortOption.sortBy,
                    sortOrder: sortOption.sortOrder,
                    board: selectedBoard.rawValue,
                    policy: policy
                )
            }
            members = newMembers
            hasMoreData = newMembers.count >= pageSize
        } catch {
            if error is CancellationError { return }
            loadError = error
            print("[SectorMemberList] 成分股加载失败: \(error)")
        }
    }

    private func loadMoreMembers() async {
        guard !isLoadingMore, hasMoreData else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = currentPage + 1
        do {
            let newMembers: [SectorMemberItem]
            if isConcept && !isTHSIndex {
                newMembers = try await MarketService.fetchConceptMembers(
                    conceptId: sectorCode,
                    page: nextPage,
                    pageSize: pageSize,
                    policy: .skipCache
                )
            } else {
                newMembers = try await MarketService.fetchSectorMembers(
                    code: sectorCode,
                    page: nextPage,
                    pageSize: pageSize,
                    sortBy: sortOption.sortBy,
                    sortOrder: sortOption.sortOrder,
                    board: selectedBoard.rawValue,
                    policy: .skipCache
                )
            }
            if newMembers.isEmpty {
                hasMoreData = false
            } else {
                members.append(contentsOf: newMembers)
                currentPage = nextPage
                hasMoreData = newMembers.count >= pageSize
            }
        } catch {
            if error is CancellationError { return }
            print("[SectorMemberList] 加载更多失败: \(error)")
        }
    }

    // MARK: - 排序

    private func toggleNameSort() {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch sortOption {
            case .nameAsc:
                sortOption = .nameDesc
            default:
                sortOption = .nameAsc
            }
        }
        Task { await reloadMembers() }
    }

    private func togglePctChangeSort() {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch sortOption {
            case .pctChangeDesc:
                sortOption = .pctChangeAsc
            default:
                sortOption = .pctChangeDesc
            }
        }
        Task { await reloadMembers() }
    }

    private var nameSortIcon: String {
        switch sortOption {
        case .nameAsc: return "chevron.up"
        case .nameDesc: return "chevron.down"
        default: return "chevron.up.chevron.down"
        }
    }

    private var pctChangeSortIcon: String {
        switch sortOption {
        case .pctChangeAsc: return "chevron.up"
        case .pctChangeDesc: return "chevron.down"
        default: return "chevron.up.chevron.down"
        }
    }
}

// MARK: - 排序选项

private enum MemberSortOption {
    case nameAsc
    case nameDesc
    case pctChangeAsc
    case pctChangeDesc

    var sortBy: String {
        switch self {
        case .nameAsc, .nameDesc:
            return "con_name"
        case .pctChangeAsc, .pctChangeDesc:
            return "pct_change"
        }
    }

    var sortOrder: String {
        switch self {
        case .nameAsc, .pctChangeAsc:
            return "asc"
        case .nameDesc, .pctChangeDesc:
            return "desc"
        }
    }

    var isNameSort: Bool {
        switch self {
        case .nameAsc, .nameDesc: return true
        default: return false
        }
    }

    var isPctChangeSort: Bool {
        switch self {
        case .pctChangeAsc, .pctChangeDesc: return true
        default: return false
        }
    }
}

// MARK: - 板块筛选

private enum MemberBoardFilter: String, CaseIterable, Identifiable {
    case all
    case main
    case star
    case chuang
    case bj
    case st
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "全部"
        case .main: return "主板"
        case .star: return "科创板"
        case .chuang: return "创业板"
        case .bj: return "北交所"
        case .st: return "ST"
        case .other: return "其他"
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            SectorMemberListView(sectorCode: "885431")
                .padding()
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
