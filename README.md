# Widgets Studio

一个 iOS 个人信息仪表盘应用。当前以天气、时钟等桌面小组件作为切入点，后续计划向股票、金融数据等个人资产管理方向演进。

## 功能

- **底部 Tab 栏**：首页、组件、设置、登录四个页面
- **登录**：支持 Apple 登录 + 邮箱登录（后端接口预留）
- **首页**：显示天气等个人数据
- **组件**：时钟、天气等 iOS 桌面小组件
- **网络层**：通用 `NetworkService`，支持 Token、统一错误处理

## 项目结构

```
WidgetsStudio/
├── App/
│   └── WidgetsStudioApp.swift    # 应用入口
├── Views/
│   ├── ContentView.swift         # Tab 栏容器
│   ├── HomeView.swift            # 首页（天气）
│   ├── WidgetsView.swift         # 组件列表
│   ├── SettingsView.swift        # 设置页
│   └── LoginView.swift           # 登录页
├── Services/
│   ├── API/
│   │   ├── APIConfiguration.swift  # 基础 URL、环境配置
│   │   ├── APIError.swift          # 统一错误类型
│   │   └── NetworkService.swift    # 通用网络请求（支持 Token）
│   ├── Auth/
│   │   └── AuthService.swift       # 登录相关
│   ├── Weather/
│   │   ├── WeatherModels.swift     # 天气接口模型
│   │   └── WeatherService.swift    # 天气业务接口
├── Models/
│   └── WeatherInfo.swift           # 天气数据模型
└── Assets.xcassets/                # 应用图标
    └── AppIcon.appiconset/

WidgetsStudioWidget/              # Widget 扩展
├── ClockWidget.swift             # 时钟组件
├── WeatherWidget.swift           # 天气组件
├── Resources/                    # Info.plist、权限配置
└── WidgetsStudioWidgetBundle.swift

Docs/                             # 文档
```

## 技术栈

- SwiftUI
- WidgetKit
- URLSession（Open-Meteo 天气 API）

## 运行要求

- iOS 17.0+
- Xcode 15.0+

## 运行方式

1. 用 Xcode 打开 `WidgetsStudio.xcodeproj`
2. 选择目标设备或模拟器
3. 按 Cmd+R 运行主 App
4. 登录页支持 Apple 登录和邮箱登录（邮箱登录目前是 UI 占位，需接后端）

## 后续方向

- 股票/基金数据展示
- 个人资产 dashboard
- 行情提醒小组件
- 自选股同步

## 注意事项

- 天气数据使用免费 Open-Meteo API
- 登录接口为占位实现，需接入自己的后端
- WidgetKit 组件刷新受系统调度控制，不是实时刷新
- 真机运行需要在 Xcode 中配置正确的开发团队
