import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house")
                }

            MarketView()
                .tabItem {
                    Label("行情", systemImage: "chart.line.uptrend.xyaxis")
                }

            WidgetsView()
                .tabItem {
                    Label("组件", systemImage: "square.grid.2x2")
                }

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }

            LoginView()
                .tabItem {
                    Label("登录", systemImage: "person.circle")
                }
        }
    }
}

#Preview {
    ContentView()
}
