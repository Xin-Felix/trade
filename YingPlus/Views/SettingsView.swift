import SwiftUI

struct SettingsView: View {
    @Binding var isLoggedIn: Bool
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @State private var userProfile: UserProfile?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileSection
                    pointsSection
                    menuSection
                }
                .padding()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("我的")
            .task {
                await loadProfile()
            }
            .onReceive(NotificationCenter.default.publisher(for: .userProfileUpdated)) { _ in
                Task { await loadProfile() }
            }
        }
    }

    // MARK: - 数据加载

    private func loadProfile() async {
        do {
            userProfile = try await UserService.fetchProfile()
        } catch {
            print("[Settings] 用户信息加载失败: \(error)")
        }
    }

    // MARK: - 头像 & 用户信息

    private var profileSection: some View {
        NavigationLink {
            ProfileEditView()
        } label: {
            HStack(spacing: 16) {
                profileAvatar
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(userProfile?.name ?? "盈多多用户")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(userProfile?.email ?? "AI 投资工作台")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var profileAvatar: some View {
        if let avatarURL = userProfile?.avatar, let url = URL(string: avatarURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image("AppLogo")
                        .resizable()
                        .scaledToFill()
                }
            }
        } else {
            Image("AppLogo")
                .resizable()
                .scaledToFill()
        }
    }

    // MARK: - 积分 & 会员

    private var pointsSection: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.circle.fill")
                            .foregroundStyle(YPColor.warning)
                        Text("我的积分")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Text("0")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(YPColor.warning)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("免费版")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.gray)
                        .clipShape(Capsule())
                    Text("解锁更多 AI 功能")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            Divider()
                .padding(.horizontal)

            HStack(spacing: 0) {
                pointsAction(icon: "plus.circle", title: "充值积分")
                pointsAction(icon: "clock.arrow.circlepath", title: "积分记录")
                pointsAction(icon: "crown", title: "会员特权")
                pointsAction(icon: "gift", title: "邀请奖励")
            }
            .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func pointsAction(icon: String, title: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(YPColor.accent)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 功能菜单

    private var menuSection: some View {
        VStack(spacing: 0) {
            NavigationLink {
                ContentManageView()
            } label: {
                menuRow(icon: "square.and.pencil", title: "内容管理", color: YPColor.warning)
            }

            Divider().padding(.leading, 52)

            NavigationLink {
                AppSettingsView(isLoggedIn: $isLoggedIn, appearanceMode: $appearanceMode)
            } label: {
                menuRow(icon: "gear", title: "设置", color: .secondary)
            }

            Divider().padding(.leading, 52)

            menuRow(icon: "questionmark.circle", title: "帮助与反馈", color: YPColor.accent)

            Divider().padding(.leading, 52)

            NavigationLink {
                AboutView()
            } label: {
                menuRow(icon: "info.circle", title: "关于盈多多", color: YPColor.ai)
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func menuRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

// MARK: - 设置子页面

struct AppSettingsView: View {
    @Binding var isLoggedIn: Bool
    @Binding var appearanceMode: Int

    var body: some View {
        List {
            Section("外观") {
                Picker("主题模式", selection: $appearanceMode) {
                    Text("跟随系统").tag(0)
                    Text("浅色").tag(1)
                    Text("深色").tag(2)
                }
                .pickerStyle(.segmented)
            }

            Section("缓存") {
                HStack {
                    Text("清除缓存")
                    Spacer()
                    Text("--")
                        .foregroundStyle(.secondary)
                }
            }

            Section("账号") {
                Button("退出登录", role: .destructive) {
                    AuthService.logout()
                    isLoggedIn = false
                }
            }

            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Text("盈多多不提供交易服务，仅帮助投资者获取信息、理解市场、管理投资并辅助决策。")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } header: {
                Text("免责声明")
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 内容管理（预留）

struct ContentManageView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.richtext")
                .font(.system(size: 56))
                .foregroundStyle(YPColor.warning.opacity(0.6))

            Text("内容管理")
                .font(.title2)
                .fontWeight(.semibold)

            Text("发布投资笔记、交易心得、市场观点\n与社区分享你的投资智慧")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                featurePreview(icon: "pencil.line", title: "发布内容", desc: "撰写投资笔记与分析")
                featurePreview(icon: "text.book.closed", title: "我的文章", desc: "管理已发布的内容")
                featurePreview(icon: "chart.bar.doc.horizontal", title: "数据统计", desc: "查看阅读量与互动")
            }
            .padding(.top, 8)

            Spacer()

            Text("即将上线，敬请期待")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 32)
        }
        .padding()
        .navigationTitle("内容管理")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func featurePreview(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(YPColor.warning)
                .frame(width: 36, height: 36)
                .background(YPColor.warning.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - 关于页面

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Logo & 品牌
                VStack(spacing: 12) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: YPColor.ai.opacity(0.3), radius: 10, y: 4)

                    Text("盈多多 Ying+")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Invest Smarter.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()

                    Text("版本 1.0.0")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 24)

                // 产品定位
                VStack(alignment: .leading, spacing: 12) {
                    aboutSectionTitle("产品定位")

                    Text("盈多多是一款 AI 投资工作台，不提供交易服务，而是帮助投资者获取信息、理解市场、管理投资并辅助决策。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // 产品理念
                VStack(alignment: .leading, spacing: 12) {
                    aboutSectionTitle("产品理念")

                    Text("盈多多不是告诉用户买什么，而是帮助用户知道市场发生了什么，并更有依据地做自己的投资决策。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // 核心能力
                VStack(alignment: .leading, spacing: 12) {
                    aboutSectionTitle("核心能力")

                    VStack(spacing: 10) {
                        abilityRow(icon: "brain", title: "AI 智能分析", desc: "市场、个股、公告、财报全方位 AI 解读")
                        abilityRow(icon: "chart.line.uptrend.xyaxis", title: "实时行情", desc: "A股行情、板块资金流向、龙虎榜数据")
                        abilityRow(icon: "star", title: "自选管理", desc: "自选股跟踪、每日复盘、AI 仓位建议")
                        abilityRow(icon: "globe", title: "全球视野", desc: "美股、港股、日韩、黄金、原油一览")
                        abilityRow(icon: "bell", title: "智能提醒", desc: "个股异动、公告推送、市场情绪预警")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // 品牌视觉
                VStack(alignment: .leading, spacing: 12) {
                    aboutSectionTitle("品牌视觉")

                    HStack(spacing: 12) {
                        colorSwatch(color: YPColor.brandBlue, name: "品牌蓝")
                        colorSwatch(color: YPColor.brandPurple, name: "科技紫")
                        colorSwatch(color: YPColor.brandCyan, name: "青色")
                        colorSwatch(color: YPColor.up, name: "涨")
                        colorSwatch(color: YPColor.down, name: "跌")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // 免责声明
                VStack(alignment: .leading, spacing: 8) {
                    aboutSectionTitle("免责声明")

                    Text("本应用仅供学习研究和投资参考使用，不构成任何投资建议。投资有风险，入市需谨慎。用户根据本应用信息所做的投资决策，由用户自行承担风险和责任。")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("© 2025 盈多多 Ying+. All rights reserved.")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
                    .padding(.bottom, 24)
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func aboutSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
    }

    private func abilityRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(YPColor.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func colorSwatch(color: Color, name: String) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 36, height: 36)
            Text(name)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SettingsView(isLoggedIn: .constant(true))
}
