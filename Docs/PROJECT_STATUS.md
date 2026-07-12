# 盈多多 iOS 项目进度

> 更新时间：2026-07-10

## 已完成功能

### 1. 页面框架搭建
- TabView 五个 Tab：首页 / 市场 / AI / 自选 / 我的
- 各模块占位页面搭建完成

### 2. 首页 (HomeView)
- **大盘指数** — 接口 `/stocks/indices`，实时显示上证/深证/创业板点位和涨跌幅
- **北向资金** — 接口 `/stocks/moneyflow-hsgt`，今日合计、日变化、沪股通/深股通
- **热点板块** — 接口 `/stocks/sector-moneyflow`，资金流入排行 TOP8
- 市场概览旁"查看全部" → 大盘指数列表页 (`IndicesListView`) → 单个指数详情 (`IndexDetailView`)
- 热点板块旁"查看全部" → 全部板块排行页 (`AllSectorsView`) → 板块详情 + 成分股列表 (`SectorDetailView`)

### 3. 市场 (MarketView)
- **股票搜索** — 本地缓存 + 拼音/代码/名称模糊搜索
- **板块中心**：
  - 每日资金流向 — 原有的 `SectorMoneyflowTrendView`（按天趋势折线图）
  - 分时资金流向 — 新开发的 `SectorIntradayFlowView`（气泡动画 + 播放器）
- **龙虎榜** — 接口 `/stocks/top-list`，今日上榜个股列表
- 板块关联分析 / 个股异动 — 占位

### 4. 分时资金气泡流动画 (MoneyFlowBubbleView)
- 气泡大小 = 资金量，Y轴位置 = 流入在上/流出在下
- X轴按 ID 固定列位（不左右跳）
- 碰撞分离算法（贴合但不重叠）
- 粒子流：从绿气泡（流出）→ 红气泡（流入），带拖尾方向
- 每个红气泡保证至少有一条粒子流指向
- 粒子目标切换时平滑转向（找最近红气泡）
- 气泡数量可调（4~20），Stepper 控制
- 播放器：播放/暂停、进度条拖动、0.5x/1x/2x 倍速
- Mock 数据：20个概念板块，240帧（09:31~15:00），带趋势+惯性的平滑随机游走
- **视频导出**：
  - 流式渲染（不缓存全部帧，避免内存溢出）
  - HEVC 编码 15Mbps，60fps，@3x 分辨率
  - 帧间数据线性插值（消除气泡位置跳变）
  - 导出时禁用浮动动画（避免每帧随机抖动）
  - 保存到相册

### 5. 自选 (WatchlistView)
- 后端自选股同步 — 接口 `/stocks/watchlist` (GET/POST/DELETE)
- 本地缓存镜像快速判断星标状态
- 每日复盘 / AI 仓位建议 — 占位

### 6. 个人信息 (SettingsView + ProfileEditView)
- "我的"页面：头像、昵称、邮箱（从后端加载真实数据）
- 编辑资料页：
  - 头像上传 — `POST /upload/avatar`，OSS 公共读直链
  - 图片限制：5MB 上限 + 压缩到 500KB + 正方形裁切 (`ImageCropView`)
  - 昵称修改 — `PUT /auth/me`
- 全局刷新：`Notification.Name.userProfileUpdated`，编辑后返回自动更新
- 积分 / 会员 / 内容管理 / 关于页 — 已搭建

### 7. 股票详情 (StockDetailView)
- K线图（日/周/月/年/分时）
- 主力资金流
- 日线因子（PE/PB/换手率等）
- 板块 / 新闻 / 公告 / 财务 / 龙虎榜 — 标记待开发

### 8. 认证 (AuthService)
- 邮箱验证码登录/注册
- 密码登录（测试账号）
- Token 自动注入 + 401 自动登出
- Keychain 持久化

### 9. UI / 品牌
- Theme.swift：品牌色系（蓝/紫/青/红涨绿跌）
- App 图标替换（全尺寸）
- 外观模式切换（跟随系统/浅色/深色）

## 后端接口对接状态

| 接口 | 状态 | 用途 |
|------|------|------|
| `POST /auth/email/code` | ✅ | 发送验证码 |
| `POST /auth/email/verify` | ✅ | 验证码登录 |
| `POST /auth/login/email` | ✅ | 密码登录 |
| `GET /auth/me` | ✅ | 获取用户信息 |
| `PUT /auth/me` | ✅ | 修改昵称 |
| `POST /upload/avatar` | ✅ | 头像上传 OSS |
| `GET /stocks/quote/{code}` | ✅ | 个股行情 |
| `GET /stocks/klines/{code}` | ✅ | K线数据 |
| `GET /stocks/intraday/{code}` | ✅ | 分时数据 |
| `GET /stocks/basics` | ✅ | 股票列表缓存 |
| `GET /stocks/search` | ✅ | 股票搜索 |
| `GET /stocks/indices` | ✅ | 大盘指数 |
| `GET /stocks/index-daily/{code}` | ✅ | 指数日线 |
| `GET /stocks/daily-basic/{code}` | ✅ | 日线因子 |
| `GET /stocks/sector-moneyflow` | ✅ | 板块资金流排行 |
| `GET /stocks/sector-moneyflow/trend` | ✅ | 板块资金流趋势 |
| `GET /stocks/ths-member/{code}` | ✅ | 板块成分股 |
| `GET /stocks/moneyflow-hsgt` | ✅ | 北向资金 |
| `GET /stocks/moneyflow/{code}` | ✅ | 个股资金流 |
| `GET /stocks/top-list` | ✅ | 龙虎榜 |
| `GET /stocks/top-inst` | ✅ | 龙虎榜机构 |
| `GET/POST/DELETE /stocks/watchlist` | ✅ | 自选股 |
| `GET /points/balance` | ✅ | 积分余额 |
| `GET /points/records` | ✅ | 积分变动明细 |
| `GET /points/features/{feature_code}` | ✅ | 功能权限校验 |
| `GET /stocks/concepts/{code}` | ⚠️ | 概念映射（需跑 `POST /sync/concept`） |
| `POST /sync/concept` | 待执行 | 同步概念板块成分股到 stock_concept 表 |

## 文件结构

```
YingPlus/
├── App/
│   └── YingPlusApp.swift
├── Services/
│   ├── API/
│   │   ├── APIConfiguration.swift
│   │   ├── APIError.swift
│   │   └── NetworkService.swift
│   ├── Auth/
│   │   ├── AuthService.swift
│   │   ├── KeychainService.swift
│   │   └── UserService.swift          ← 用户信息 + 头像上传
│   ├── Points/
│   │   ├── PointsModels.swift         ← 积分余额/记录/权限模型
│   │   └── PointsService.swift        ← 积分 API
│   ├── MembershipService.swift        ← 会员档位/状态 API
│   ├── H5PageService.swift            ← H5 页面 API
│   ├── H5PageModels.swift             ← H5 页面模型
│   ├── Stocks/
│   │   ├── StockModels.swift
│   │   ├── StockService.swift
│   │   ├── MarketModels.swift         ← 北向资金/龙虎榜/指数/资金流模型
│   │   ├── MarketService.swift        ← 市场级数据 API
│   │   ├── ConceptFlowService.swift   ← 概念分时资金流
│   │   └── KLineCacheService.swift
│   └── VideoRecorder.swift            ← 视频导出（流式渲染）
├── Views/
│   ├── ContentView.swift
│   ├── HomeView.swift
│   ├── MarketView.swift
│   ├── AICenterView.swift
│   ├── WatchlistView.swift
│   ├── SettingsView.swift             ← 我的 + 设置 + 关于 + 积分入口
│   ├── ProfileEditView.swift          ← 编辑资料
│   ├── ImageCropView.swift            ← 正方形裁切
│   ├── Points/
│   │   ├── PointsView.swift           ← 积分主页
│   │   └── PointsHistoryView.swift    ← 积分记录
│   ├── MembershipView.swift           ← 会员中心
│   ├── H5PageView.swift               ← H5 内容展示
│   ├── LimitUpLadderView.swift        ← 涨停梯队
│   ├── SectorMemberListView.swift     ← 板块成分股列表
│   ├── StockDetailView.swift
│   ├── KLineChartView.swift
│   ├── SharedStockViews.swift
│   ├── Theme.swift
│   ├── IndicesListView.swift          ← 大盘指数列表
│   ├── AllSectorsView.swift           ← 全部板块排行
│   ├── SectorDetailView.swift         ← 板块详情 + 成分股
│   ├── SectorIntradayFlowView.swift   ← 分时资金流向（播放器）
│   ├── MoneyFlowBubbleView.swift      ← 气泡流动画
│   ├── SectorMoneyflowTrendView.swift
│   ├── SectorMoneyflowTrendChartView.swift
│   ├── LoginView.swift
│   └── APITestView.swift
└── Assets.xcassets/
    ├── AppIcon.appiconset/
    └── AppLogo.imageset/
```

## 待开发

- [ ] 分时资金流向接口对接（替换 mock 数据）
- [ ] AI 中心功能（AI 晨报 / 个股分析 / 公告解读）
- [ ] 国际市场行情数据
- [ ] 个股异动
- [ ] 板块关联分析
- [ ] 持仓管理
- [ ] Widget 小组件
- [ ] Apple Watch
