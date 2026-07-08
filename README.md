# 盈多多 / Ying+

一款面向个人投资者的 iOS 应用：以桌面小组件为切入点，聚合股票行情、自选股、持仓盈亏等关键信息，让用户以最低成本掌握资产动态。

## 功能

- **底部 Tab 栏**：首页、行情、组件、设置
- **全局登录态**：基于 JWT + Keychain，未登录时展示登录页
- **验证码登录**：输入邮箱 → 获取验证码 → 自动注册/登录
- **测试账号登录**：开发环境一键登录，方便快速体验
- **首页**：行情概览，大盘指数 + 自选股列表
- **行情页**：大盘指数 + 自选股列表（需登录），支持搜索股票代码
- **股票详情**：日 / 周 / 月 / 年 K 线图（支持缩放、平移、长按十字光标）+ 股票指标（PE/PB/PS/换手率/量比/市值/股息率）
- **组件**：行情小组件占位，后续接入自选股/持仓数据
- **网络层**：通用 `NetworkService`，支持 Token 自动注入、统一错误处理

## 项目结构

```
trade_ios/
├── YingPlus/
│   ├── App/
│   │   └── YingPlusApp.swift    # 应用入口
│   ├── Views/
│   │   ├── ContentView.swift         # 登录态判断 + Tab 栏容器
│   │   ├── HomeView.swift            # 首页（行情概览）
│   │   ├── MarketView.swift          # 行情页
│   │   ├── StockDetailView.swift     # 股票详情
│   │   ├── KLineChartView.swift      # K 线图
│   │   ├── SharedStockViews.swift    # 股票共享视图组件
│   │   ├── WidgetsView.swift         # 组件列表
│   │   ├── SettingsView.swift        # 设置页（含退出登录）
│   │   └── LoginView.swift           # 验证码登录页
│   ├── Services/
│   │   ├── API/
│   │   │   ├── APIConfiguration.swift  # 基础 URL、环境配置
│   │   │   ├── APIError.swift          # 统一错误类型
│   │   │   └── NetworkService.swift    # 通用网络请求（支持 Token）
│   │   ├── Auth/
│   │   │   ├── AuthService.swift       # 登录/认证相关
│   │   │   └── KeychainService.swift   # Token 持久化
│   │   └── Stocks/
│   │       ├── StockModels.swift       # 股票接口模型
│   │       └── StockService.swift      # 股票业务接口
│   └── Assets.xcassets/                # 应用图标
│
├── YingPlusWidget/              # Widget 扩展
│   ├── ClockWidget.swift             # 时钟组件
│   ├── WeatherWidget.swift           # 天气组件
│   └── YingPlusWidgetBundle.swift
│
└── Docs/                             # 文档
    ├── PRD.md                        # 产品需求文档
    ├── Architecture.md               # 架构文档
    ├── API.md                        # 后端接口文档
    └── PROJECT_STATUS.md             # 项目状态与开发指南
```

## 技术栈

- SwiftUI
- WidgetKit
- URLSession（后端 API）
- Keychain（Token 持久化）

## 运行要求

- iOS 17.0+
- Xcode 15.0+

## 运行方式

1. 启动后端（详见 `../trade_backend/README.md`）
2. 用 Xcode 打开 `YingPlus.xcodeproj`
3. 选择目标设备或模拟器
4. 按 Cmd+R 运行主 App

## 后端地址

开发环境默认指向：

```swift
// 局域网地址，方便真机调试
http://172.17.82.33:8000

// 模拟器本地调试也可使用
http://127.0.0.1:8000
```

可在 `YingPlus/Services/API/APIConfiguration.swift` 中修改。

## 后续方向

- 自选股云端管理（增删改查、排序）
- 持仓录入与持仓盈亏概览
- 个人资产 Dashboard
- 行情提醒小组件
- 股价推送通知
- 自选股/持仓多设备同步
- Apple 登录
- App Store 上架

## 注意事项

- 股票数据来自 Tushare，需要配置 `TUSHARE_TOKEN`
- WidgetKit 组件刷新受系统调度控制，不是实时刷新
- 真机运行需要在 Xcode 中配置正确的开发团队
- 后端为独立仓库，位于 `../trade_backend/`
