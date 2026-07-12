import SwiftUI

// MARK: - 板块关联分析（占位）

struct SectorCorrelationView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PlaceholderCard(
                    icon: "link.circle",
                    title: "功能开发中",
                    description: "分析板块之间的联动关系和资金轮动",
                    color: YPColor.info
                )
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("板块关联分析")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SectorCorrelationView()
    }
}
