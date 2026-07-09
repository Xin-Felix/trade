import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn: Bool = AuthService.restoreSession() != nil
    @State private var selectedTab = 1  // 默认选中行情 Tab
    @State private var autoLoginError: String?

    var body: some View {
        ZStack {
            if isLoggedIn {
                mainTabView
            } else {
                LoginView(isLoggedIn: $isLoggedIn, autoLoginError: autoLoginError)
            }
        }
        .task {
            await autoLoginIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionUnauthorized)) { _ in
            AuthService.logout()
            isLoggedIn = false
        }
    }

    private func autoLoginIfNeeded() async {
        guard NetworkService.shared.getAuthToken() == nil else { return }
        do {
            _ = try await AuthService.loginWithTestAccount()
            isLoggedIn = true
        } catch {
            autoLoginError = "自动登录失败: \(error.localizedDescription)"
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house")
                }
                .tag(0)

            MarketView()
                .tabItem {
                    Label("行情", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)

            WidgetsView()
                .tabItem {
                    Label("组件", systemImage: "square.grid.2x2")
                }
                .tag(2)

            APITestView()
                .tabItem {
                    Label("接口", systemImage: "network")
                }
                .tag(3)

            SettingsView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(4)
        }
    }
}

#Preview {
    ContentView()
}
