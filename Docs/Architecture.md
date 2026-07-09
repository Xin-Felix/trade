# 盈多多 / Ying+ 架构文档

## 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                         用户桌面                              │
│  ┌─────────────┐  ┌─────────────────────┐  │
│  │  时钟组件    │  │  行情提醒组件（后续） │  │
│  │  (WidgetKit)│  │  (WidgetKit)        │  │
│  └──────┬──────┘  └──────────┬──────────┘  │
└─────────┼────────────────┼────────────────────┼─────────────┘
          │                │                    │
          ▼                ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                 YingPlusWidget                          │
│            (独立 Extension，负责渲染组件)                     │
└─────────────────────────────────────────────────────────────┘
          │
          │ 共享数据（后续通过 App Groups）
          ▼
┌─────────────────────────────────────────────────────────────┐
│                    YingPlus                             │
│      (主 App：登录、行情、自选股、持仓、设置)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  LoginView   │  │  MarketView  │  │  SettingsView│      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                  │              │
│         ▼                 ▼                  ▼              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │   AuthService / StockService / PortfolioService      │  │
│  └───────────────────────┬──────────────────────────────┘  │
│                          │                                  │
│                          ▼                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │        NetworkService  ◄──►  APIConfiguration         │  │
│  └───────────────────────┬──────────────────────────────┘  │
└──────────────────────────┼──────────────────────────────────┘
                           │ HTTPS / Bearer Token
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   trade_backend (FastAPI)                    │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │    auth    │  │   stocks   │  │   weather  │            │
│  └──────┬─────┘  └──────┬─────┘  └──────┬─────┘            │
│         │               │               │                  │
│         ▼               ▼               ▼                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              services / models / schemas              │  │
│  └───────────────────────┬──────────────────────────────┘  │
│                          │                                  │
│                          ▼                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    MySQL + Redis                      │  │
│  └───────────────────────┬──────────────────────────────┘  │
│                          │                                  │
│                          ▼                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  外部数据源：Tushare / Open-Meteo / Apple Sign In     │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 代码仓库划分

| 仓库 | 路径 | 说明 |
|---|---|---|
| iOS 客户端 | `trade_ios/` | SwiftUI + WidgetKit，包含 Docs 文档 |
| 后端服务 | `trade_backend/` | FastAPI 后端，独立 Git 仓库 |

两者通过 HTTP API 通信，后端地址由 `APIConfiguration.swift` 管理。

## 演进方向

### 当前已实现

- 全局登录态 + 邮箱验证码登录 + 测试账号登录。
- 股票行情接口（单股行情、K 线、自选股、板块资金流、板块资金趋势）。
- 行情概览首页 + 行情页 + 股票/指数详情页。
- 交互式 K 线图：缩放、平移、十字光标、长按显示当天收盘价与涨跌幅。
- 板块资金流动态趋势图：时间段选择、当日/累计切换、排序、横屏、保存相册。
- 自选股本地缓存：搜索和股票详情页可添加/移除，首页展示并支持左滑删除。
- iOS 与后端目录拆分，独立管理。

### 后续会在主 App 中增加

- 持仓录入与持仓盈亏概览。
- 个人资产 Dashboard。
- 行情推送通知。

### 后续会在 Widget 扩展中增加

- 行情提醒小组件（自选/持仓数据展示）。
- 通过 App Groups 共享缓存数据，Widget 只读取本地数据并渲染。

## 模块说明

### 主 App (YingPlus)

| 目录 | 职责 |
|------|------|
| `App/` | 应用入口 `@main` |
| `Views/` | SwiftUI 界面：登录、首页、行情、股票详情、指数详情、K 线、板块资金、组件列表、设置 |
| `Services/API/` | 通用网络层：请求、错误处理、Token 注入 |
| `Services/Auth/` | 登录/认证、Keychain Token 持久化 |
| `Services/Stocks/` | 股票业务接口、数据模型、自选股本地缓存、K 线本地缓存 |
| `Assets.xcassets/` | 应用图标与资源 |

### 网络层

```
Views ──▶ AuthService / StockService ──▶ NetworkService ──▶ 后端 API
              │                              │
              ▼                              ▼
        Auth / Stock Models             APIConfiguration / APIError
```

- **NetworkService**：通用 HTTP 客户端，自动注入 Bearer Token，统一处理 401/500。
- **APIConfiguration**：管理基础 URL（开发/生产环境）和超时时间。
- **APIError**：统一错误类型，包含中文错误信息。
- **AuthService**：验证码登录、测试账号登录、Token 恢复/登出。
- **KeychainService**：安全存储 access token。

### Widget 扩展 (YingPlusWidget)

| 文件 | 职责 |
|------|------|
| `YingPlusWidgetBundle.swift` | Widget 入口，注册所有组件 |
| `ClockWidget.swift` | 时钟组件：TimelineProvider + View |
| `WeatherWidget.swift` | 天气组件：TimelineProvider + View（保留，后续替换为行情组件） |
| `Resources/Info.plist` | 扩展声明 |
| `Resources/YingPlusWidget.entitlements` | 权限配置 |

Widget 扩展已正常嵌入主 App Target（`Embed Foundation Extensions`）。

## 数据流

### 当前实现：行情页与股票详情

1. `HomeView` / `MarketView` / `StockDetailView` / `IndexDetailView` 调用 `StockService`。
2. `StockService` 通过 `NetworkService` 向后端发送带 Token 的请求。
3. 后端从 Tushare 拉取数据并返回，iOS 端解码后展示。
4. `KLineChartView` 使用 SwiftUI `Canvas` + `Gesture` 实现缩放、平移、十字光标，长按可将当天收盘价与涨跌幅回传给父视图更新 header。
5. `SectorMoneyflowTrendChartView` 使用 `Canvas` 自绘多折线，支持当日/累计切换、排序、横屏、保存相册。
6. 自选股通过 `WatchlistService` 存储在 `UserDefaults`，不依赖后端。

### 推荐演进：行情提醒小组件

1. 主 App 负责请求后端行情/持仓数据。
2. 数据通过 App Groups 共享给 Widget（使用 `UserDefaults` / `FileManager` 共享容器）。
3. Widget 只读取本地缓存并渲染，不直接发起网络请求。
4. 这样更省电、更稳定，也符合 WidgetKit 的设计约束。

## WidgetKit 限制

- 组件不是小 App，交互受限（主要支持点击打开主 App）。
- 刷新由系统调度，开发者只能建议刷新时间（`reloadPolicy`）。
- 不能播放动画/视频。
- 组件尺寸固定：小、中、大、超大。
- 复杂 UI 需使用 `accessoryInline` / `accessoryCircular` / `accessoryRectangular` 等系统模板（iOS 16+）。

## 安全与持久化

| 数据 | 存储位置 | 说明 |
|---|---|---|
| Access Token | Keychain | 主 App 重启后自动恢复登录态 |
| 自选股 | UserDefaults（iOS 端） | 用户手动添加/移除，不与后端同步 |
| 股票基础信息列表 | 本地文件（Documents） | `StockListCacheService` 每天刷新一次，供搜索使用 |
| K 线数据 | 本地文件（Documents） | `KLineCacheService` 按 code + period 缓存，支持增量更新 |
| Widget 共享数据 | App Groups（后续） | 主 App 写、Widget 读 |

## 部署关系

- iOS App 通过 `APIConfiguration.baseURL` 连接后端。
- 开发环境默认指向局域网地址 `http://192.168.31.86:8000`，真机调试时确保手机与 Mac 在同一局域网。
- 生产环境应切换为 HTTPS 域名，并在 `production` 环境中配置。
