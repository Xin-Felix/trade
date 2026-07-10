import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn: Bool = AuthService.restoreSession() != nil
    @State private var selectedTab = 0  // 默认选中首页 Tab
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
                    Label("市场", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)

            AICenterView()
                .tabItem {
                    Label("AI", systemImage: "brain")
                }
                .tag(2)

            WatchlistView()
                .tabItem {
                    Label("自选", systemImage: "star")
                }
                .tag(3)

            SettingsView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Label("我的", systemImage: "person")
                }
                .tag(4)
        }
    }
}

#Preview {
    ContentView()
}
