# Widgets Studio 架构文档

## 整体架构

```
┌─────────────────────────────────────┐
│           用户桌面                   │
│  ┌─────────────┐  ┌─────────────┐  │
│  │  时钟组件    │  │  天气组件    │  │
│  │  (WidgetKit)│  │  (WidgetKit)│  │
│  └──────┬──────┘  └──────┬──────┘  │
└─────────┼────────────────┼──────────┘
          │                │
          ▼                ▼
┌─────────────────────────────────────┐
│      WidgetsStudioWidget            │
│  (独立 Extension，负责渲染组件)       │
└─────────────────────────────────────┘
          │
          │ 共享数据（后续可接 App Groups）
          ▼
┌─────────────────────────────────────┐
│         WidgetsStudio               │
│  (主 App：登录、行情、个人资产)       │
└─────────────────────────────────────┘
```

## 演进方向

当前架构以小组件验证技术链路，后续会在主 App 中增加：

- 登录/用户系统
- 股票/基金行情模块
- 自选股管理
- 资产 Dashboard

Widget 扩展未来主要用于展示行情提醒、自选股价等轻量信息。

## 模块说明

### 主 App (WidgetsStudio)

| 目录 | 职责 |
|------|------|
| App | 应用入口 `@main` |
| Views | SwiftUI 界面 |
| Services/API | 通用网络层：请求、错误处理、Token 管理 |
| Services/Auth | 登录/认证相关 |
| Services/Weather | 天气业务接口 |
| Models | 数据模型定义 |
| Assets.xcassets | 应用图标 |

### 网络层

```
Views ──▶ WeatherService ──▶ NetworkService ──▶ 后端 API
              │                      │
              ▼                      ▼
        WeatherModels          APIConfiguration / APIError
```

- **NetworkService**：通用 HTTP 客户端，支持 GET/POST/PUT/DELETE/PATCH，自动注入 Bearer Token
- **APIConfiguration**：管理基础 URL 和环境配置
- **APIError**：统一错误类型，包含中文错误信息
- **AuthService**：登录接口占位，登录成功后自动设置 Token

### Widget 扩展 (WidgetsStudioWidget)

| 文件 | 职责 |
|------|------|
| WidgetsStudioWidgetBundle.swift | Widget 入口，注册所有组件 |
| ClockWidget.swift | 时钟组件：TimelineProvider + View |
| WeatherWidget.swift | 天气组件：TimelineProvider + View |
| Resources/Info.plist | 扩展声明 |
| Resources/WidgetsStudioWidget.entitlements | 权限配置 |

## 数据流

### 当前实现（天气）

1. Widget 在 `getTimeline` 中直接请求 Open-Meteo API
2. 拿到数据后生成 TimelineEntry
3. WidgetKit 按时间轴渲染组件

### 推荐演进（后续）

1. 主 App 负责请求网络数据
2. 数据通过 App Groups 共享给 Widget
3. Widget 只读取本地缓存并渲染
4. 这样更省电、更稳定

## WidgetKit 限制

- 组件不是小 App，交互受限
- 刷新由系统调度，开发者只能建议时间
- 不能播放动画/视频
- 组件尺寸固定（小/中/大/超大）
