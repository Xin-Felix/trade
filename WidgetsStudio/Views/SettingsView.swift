import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("关于") {
                    HStack {
                        Text("应用名称")
                        Spacer()
                        Text("Widgets Studio")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("小组件") {
                    Text("长按桌面 → 点击左上角 + → 选择 Widgets Studio")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
        }
    }
}

#Preview {
    SettingsView()
}
