import SwiftUI

// MARK: - 个股异动（占位）

struct UnusualMovesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PlaceholderCard(
                    icon: "bolt.circle",
                    title: "功能开发中",
                    description: "涨停、跌停、大单买入等异常变动",
                    color: YPColor.up
                )
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("个股异动")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        UnusualMovesView()
    }
}
