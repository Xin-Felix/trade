import SwiftUI

struct SettingsView: View {
    @Binding var isLoggedIn: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                List {
                    Section("账号") {
                        Button("退出登录", role: .destructive) {
                            AuthService.logout()
                            isLoggedIn = false
                        }
                    }

                    Section("关于") {
                        HStack {
                            Text("应用名称")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("盈多多")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("版本")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("1.0")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("小组件") {
                        Text("长按桌面 → 点击左上角 + → 选择 盈多多")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("设置")
        }
    }
}

#Preview {
    SettingsView(isLoggedIn: .constant(true))
}
