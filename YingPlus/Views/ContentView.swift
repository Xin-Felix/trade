import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn: Bool = AuthService.restoreSession() != nil
    @SceneStorage("selectedTab") private var selectedTab = 0
    @State private var autoLoginError: String?
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @State private var paymentInfo: PaymentRequiredInfo?
    @State private var showMembershipSheet = false

    @State private var showSplash = true
    @State private var preloadedHomeData: PreloadedHomeData?

    var body: some View {
        ZStack {
            if isLoggedIn {
                mainTabView
            } else {
                LoginView(isLoggedIn: $isLoggedIn, autoLoginError: autoLoginError)
            }

            if showSplash {
                SplashView { data, loginError in
                    preloadedHomeData = data
                    autoLoginError = loginError
                    showSplash = false
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            updateWindowAppearance()
        }
        .onChange(of: appearanceMode) { _, _ in
            updateWindowAppearance()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionUnauthorized)) { _ in
            AuthService.logout()
            isLoggedIn = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .paymentRequired)) { notification in
            if let info = notification.object as? PaymentRequiredInfo {
                paymentInfo = info
                showMembershipSheet = true
            }
        }
        .sheet(isPresented: $showMembershipSheet) {
            MembershipView(paymentInfo: paymentInfo)
        }
    }

    private func updateWindowAppearance() {
        DispatchQueue.main.async {
            let style: UIUserInterfaceStyle
            switch appearanceMode {
            case 1: style = .light
            case 2: style = .dark
            default: style = .unspecified
            }
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .forEach { $0.overrideUserInterfaceStyle = style }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView(preloadedData: preloadedHomeData)
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
