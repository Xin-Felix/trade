# 盈多多 / Ying+ 架构文档

> 更新时间：2026-07-08

## 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                         iOS App (YingPlus)                       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────┐ │
│  │ HomeView │ │MarketView│ │WidgetView│ │APITestView│ │Setting│ │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬──────┘ └──┬───┘ │
│       └─────────────┴────────────┴─────────────┴───────────┘     │
│                              │                                    │
│       AuthService / StockService / WatchlistService               │
│                              │                                    │
│              NetworkService + APIConfiguration                    │
└──────────────────────────────┼────────────────────────────────────┘
                               │ HTTP + Bearer Token
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│                    trade_backend (FastAPI + Docker)               │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  /api/v1/auth     认证（邮箱验证码/密码登录）                │  │
│  │  /api/v1/stocks   股票业务（行情/K线/自选/概念/资金流/龙虎榜）│  │
│  │  /api/v1/sync     数据同步（后台任务触发）                   │  │
│  │  /api/v1/ts       Tushare代理（124个接口直接透传）           │  │
│  └────────────────────────────────────────────────────────────┘  │
│                              │                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │           services / models / schemas                      │  │
│  └─────────────────────────┬──────────────────────────────────┘  │
│                            │                                      │
│  ┌─────────────┐  ┌───────┴───────┐  ┌───────────────────────┐  │
│  │ PostgreSQL  │  │    Redis      │  │  外部数据源            │  │
│  │ (TimescaleDB)│  │  (缓存/分时)  │  │  Tushare Pro (付费)   │  │
│  │             │  │              │  │  akshare (实时分时)    │  │
│  └─────────────┘  └──────────────┘  └───────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## 后端路由架构

```
/api/v1/
├── auth/                    # 认证
│   ├── POST /email/code     # 发送验证码
│   ├── POST /email/verify   # 验证码登录
│   └── POST /login/email    # 密码登录（测试用）
├── stocks/                  # 股票业务（读本地 DB）
│   ├── GET /quote/{code}    # 单股行情
│   ├── GET /klines/{code}   # K线（日/周/月/年）
│   ├── GET /intraday/{code} # 分时K线（akshare实时）
│   ├── GET /indices         # 大盘指数
│   ├── GET /search          # 股票搜索
│   ├── GET /basics          # 全部股票列表
│   ├── GET /daily-basic/{code} # 日线因子
│   ├── GET /watchlist       # 自选股CRUD
│   ├── GET /sector-moneyflow    # 板块资金排行
│   ├── GET /sector-moneyflow/trend # 板块资金趋势
│   ├── GET /moneyflow/{code}    # 个股资金流
│   ├── GET /moneyflow-hsgt      # 沪深港通
│   ├── GET /index-daily/{code}  # 指数日线
│   ├── GET /stock-limit     # 涨跌停
│   ├── GET /top-list        # 龙虎榜
│   ├── GET /top-inst        # 龙虎榜机构
│   ├── GET /ths-index       # THS指数列表
│   ├── GET /ths-daily/{code}# THS指数行情
│   ├── GET /ths-member/{code}# THS成分股
│   └── GET /concepts/{code} # 股票概念/题材归属
├── sync/                    # 数据同步（后台任务）
│   ├── POST /recent         # 全量增量同步
│   ├── POST /daily-kline    # 日K线
│   ├── POST /daily-basic    # 日线因子
│   ├── POST /sector-moneyflow # 板块资金
│   ├── POST /stock-moneyflow  # 个股资金
│   ├── POST /index-daily    # 指数日线
│   ├── POST /hsgt           # 沪深港通
│   ├── POST /stock-limit    # 涨跌停
│   └── POST /concept        # 概念板块成分映射
├── ts/                      # Tushare 代理（124个，直接透传）
│   ├── 一、股票基础/行情 (12个)
│   ├── 二、财务数据 (10个)
│   ├── 三、参考数据 (15个)
│   ├── 四、打板/题材/龙虎榜 (27个)
│   ├── 五、资金流向 (8个)
│   ├── 六、两融数据 (4个)
│   ├── 七、特色数据 (11个)
│   ├── 八、ETF/基金 (11个)
│   ├── 九、指数 (14个)
│   └── 十、宏观/新闻 (14个)
└── weather/                 # 天气（保留）
```

## 代码目录结构

### 后端 (trade_backend)

```
trade_backend/
├── app/
│   ├── api/v1/endpoints/
│   │   ├── auth.py          # 认证接口
│   │   ├── stocks.py        # 股票业务接口（读DB）
│   │   ├── sync.py          # 数据同步接口
│   │   ├── weather.py       # 天气接口
│   │   └── tushare/         # Tushare 代理（一接口一文件）
│   │       ├── __init__.py  # 统一入口 + 接口目录索引
│   │       ├── _base.py     # 公共工具
│   │       ├── daily.py     # 历史日线
│   │       ├── ... (124个接口文件)
│   │       └── anns_d.py    # 上市公司公告
│   ├── core/                # 配置、安全、Redis
│   ├── db/                  # 数据库连接
│   ├── models/              # ORM 模型（stock.py, watchlist.py等）
│   ├── schemas/             # Pydantic 响应模型
│   └── services/            # 业务逻辑（stock_service, auth_service等）
├── scripts/                 # 数据同步脚本
├── docker-compose.yml
└── Dockerfile
```

### iOS (trade_ios)

```
trade_ios/YingPlus/
├── App/                     # 应用入口
├── Views/
│   ├── ContentView.swift    # 根视图（登录态判断）
│   ├── HomeView.swift       # 首页（指数+自选）
│   ├── MarketView.swift     # 行情（搜索）
│   ├── StockDetailView.swift # 股票详情（分时+K线+指标）
│   ├── KLineChartView.swift # K线图组件
│   ├── SectorMoneyflowTrendView.swift # 板块资金趋势
│   ├── APITestView.swift    # 接口测试Tab
│   └── ...
├── Services/
│   ├── API/                 # 网络层
│   ├── Auth/                # 认证服务
│   └── Stocks/              # 股票服务+模型+缓存
└── Docs/                    # 项目文档
```

## 数据流

### 两条数据通路

1. **本地数据库路径** (`/stocks/*`)：数据已通过 sync 接口落库到 PostgreSQL，读取速度快，适合日常使用。
2. **Tushare 透传路径** (`/ts/*`)：直接调用 Tushare Pro API，不存库，适合探索数据、验证策略、快速查看最新数据。

### 分时行情数据流

```
iOS StockDetailView → StockService.fetchIntradayKlines()
    → 后端 /stocks/intraday/{code}
        → akshare 实时拉取 → Redis 缓存（盘中30秒，收盘后7天）
        → 返回给 iOS
iOS 每60秒自动刷新一次
```

### 概念/题材数据流

```
用户触发 POST /sync/concept → 后端后台任务
    → ths_index(type=N) 获取全部概念列表
    → 逐个调 ths_member 获取成分股
    → upsert 到 stock_concept 表

iOS 查询 GET /stocks/concepts/000001
    → 从 stock_concept 表读取该股票的全部概念归属
```

## 安全与持久化

| 数据 | 存储位置 | 说明 |
|---|---|---|
| Access Token | iOS Keychain | 主 App 重启后自动恢复 |
| 自选股 | 后端 watchlist 表 + iOS 本地缓存 | 双向同步 |
| 股票基础信息 | iOS 本地文件 | 每天刷新一次 |
| K 线缓存 | iOS 本地文件 | 按 code+period 缓存，支持增量 |
| 分时缓存 | Redis | 盘中30秒TTL，收盘后7天 |

## 部署

```bash
# 后端（Docker）
cd trade_backend
docker compose up -d --build backend

# 访问 Swagger 文档
http://192.168.31.86:8000/docs
```

开发环境 iOS 通过 `APIConfiguration.baseURL = "http://192.168.31.86:8000"` 连接后端。
