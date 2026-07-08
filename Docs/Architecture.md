# 炒股助手 / Widgets Studio 架构文档

## 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                         用户桌面                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  时钟组件    │  │  天气组件    │  │  行情提醒组件（后续） │  │
│  │  (WidgetKit)│  │  (WidgetKit)│  │  (WidgetKit)        │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
└─────────┼────────────────┼────────────────────┼─────────────┘
          │                │                    │
          ▼                ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                 WidgetsStudioWidget                          │
│            (独立 Extension，负责渲染组件)                     │
└─────────────────────────────────────────────────────────────┘
          │
          │ 共享数据（后续通过 App Groups）
          ▼
┌─────────────────────────────────────────────────────────────┐
│                    WidgetsStudio                             │
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
- 股票行情接口（单股行情、K 线、示例自选股）。
- 天气小组件 + 时钟小组件。
- iOS 与后端目录拆分，独立管理。

### 后续会在主 App 中增加

- 自选股云端管理（增删改查、排序）。
- 持仓录入与持仓盈亏概览。
- 个人资产 Dashboard。

### 后续会在 Widget 扩展中增加

- 行情提醒小组件（自选/持仓数据展示）。
- 通过 App Groups 共享缓存数据，Widget 只读取本地数据并渲染。

## 模块说明

### 主 App (WidgetsStudio)

| 目录 | 职责 |
|------|------|
| `App/` | 应用入口 `@main` |
| `Views/` | SwiftUI 界面：登录、首页、行情、股票详情、K 线、组件列表、设置 |
| `Services/API/` | 通用网络层：请求、错误处理、Token 注入 |
| `Services/Auth/` | 登录/认证、Keychain Token 持久化 |
| `Services/Stocks/` | 股票业务接口与数据模型 |
| `Services/Weather/` | 天气业务接口与数据模型 |
| `Models/` | 跨模块共享数据模型 |
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

### Widget 扩展 (WidgetsStudioWidget)

| 文件 | 职责 |
|------|------|
| `WidgetsStudioWidgetBundle.swift` | Widget 入口，注册所有组件 |
| `ClockWidget.swift` | 时钟组件：TimelineProvider + View |
| `WeatherWidget.swift` | 天气组件：TimelineProvider + View |
| `Resources/Info.plist` | 扩展声明 |
| `Resources/WidgetsStudioWidget.entitlements` | 权限配置 |

Widget 扩展已正常嵌入主 App Target（`Embed Foundation Extensions`）。

## 数据流

### 当前实现：天气小组件

1. Widget 在 `getTimeline` 中直接请求 Open-Meteo API。
2. 拿到数据后生成 TimelineEntry。
3. WidgetKit 按时间轴渲染组件。

### 当前实现：行情页

1. `MarketView` / `StockDetailView` 调用 `StockService`。
2. `StockService` 通过 `NetworkService` 向后端发送带 Token 的请求。
3. 后端从 Tushare 拉取数据并返回，iOS 端解码后展示。

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
| 自选股/持仓 | 后端 MySQL | 登录后从云端拉取 |
| Widget 共享数据 | App Groups（后续） | 主 App 写、Widget 读 |

## 部署关系

- iOS App 通过 `APIConfiguration.baseURL` 连接后端。
- 开发环境默认指向局域网地址 `http://172.17.82.33:8000`，真机调试时确保手机与 Mac 在同一局域网。
- 生产环境应切换为 HTTPS 域名，并在 `production` 环境中配置。
