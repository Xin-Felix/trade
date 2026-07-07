import SwiftUI

struct WidgetsView: View {
    let widgets = [
        WidgetItem(name: "时钟", icon: "clock", description: "显示当前时间，每分钟刷新"),
        WidgetItem(name: "天气", icon: "cloud.sun", description: "显示北京实时天气，每 30 分钟刷新")
    ]

    var body: some View {
        NavigationStack {
            List(widgets) { widget in
                HStack(spacing: 16) {
                    Image(systemName: widget.icon)
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(widget.name)
                            .font(.headline)
                        Text(widget.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("小组件")
        }
    }
}

struct WidgetItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
}

#Preview {
    WidgetsView()
}
