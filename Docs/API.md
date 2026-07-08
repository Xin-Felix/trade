# 盈多多 / Ying+ 后端接口文档

> 本文档供 iOS 端调用参考，所有业务接口前缀为 `/api/v1`。
>
> 更新时间：2026-07-08

## 目录

- [通用约定](#通用约定)
- [基础接口](#基础接口)
- [认证接口](#认证接口)
- [天气接口](#天气接口)
- [股票接口](#股票接口)
- [iOS 调用示例](#ios-调用示例)
- [错误码与处理](#错误码与处理)
- [模型映射参考](#模型映射参考)
- [后续接口规划](#后续接口规划)
- [相关文件](#相关文件)

## 通用约定

### Base URL

开发环境默认地址在 `APIConfiguration.swift` 中配置：

```swift
// 局域网地址，方便真机调试
http://172.17.82.33:8000

// 模拟器本地调试也可使用
http://127.0.0.1:8000
```

完整 API 前缀：

```
{baseURL}/api/v1
```

### 认证方式

需要登录的接口在请求头中携带：

```
Authorization: Bearer {access_token}
```

iOS 端由 `NetworkService` 自动注入，无需手动拼接。

### 请求/响应格式

- 请求：`application/json`
- 响应：`application/json`
- 时间字符串：ISO 8601 格式
- 日期字符串（K 线）：`YYYYMMDD`，例如 `20240708`

## 基础接口

### GET /

健康/服务状态。

**响应示例：**

```json
{
  "message": "Ying+ API is running"
}
```

### GET /health

健康检查。

**响应示例：**

```json
{
  "status": "ok"
}
```

## 认证接口

### POST /auth/email/code

发送邮箱验证码。

**请求体：**

```json
{
  "email": "user@example.com",
  "purpose": "login"
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `email` | string | 是 | 邮箱地址 |
| `purpose` | string | 否 | 用途：`login` / `register` / `reset_password`，默认 `login` |

**响应：**

- 成功：`204 No Content`
- 失败：`429 Too Many Requests`（请求过于频繁，5 分钟内同一邮箱同一用途最多 3 条未使用验证码）

**iOS 调用：**

```swift
try await AuthService.sendEmailCode(email: "user@example.com")
```

---

### POST /auth/email/verify

校验邮箱验证码，新用户自动注册并登录。

**请求体：**

```json
{
  "email": "user@example.com",
  "code": "123456",
  "purpose": "login"
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `email` | string | 是 | 邮箱地址 |
| `code` | string | 是 | 6 位纯数字验证码 |
| `purpose` | string | 否 | 默认 `login` |

**响应示例：**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "user": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "email": "user@example.com",
    "name": "user"
  }
}
```

**响应字段：**

| 字段 | 类型 | 说明 |
|---|---|---|
| `access_token` | string | JWT Token，有效期默认 7 天 |
| `token_type` | string | 固定为 `bearer` |
| `user.id` | string | 用户公开 ID |
| `user.email` | string | 用户邮箱 |
| `user.name` | string? | 用户昵称 |

**iOS 调用：**

```swift
let token = try await AuthService.verifyEmailCode(email: "user@example.com", code: "123456")
```

---

### POST /auth/login/email

邮箱密码登录，主要用于测试账号快速登录。

**请求体：**

```json
{
  "email": "test@example.com",
  "password": "123456"
}
```

**响应示例：** 同 `/auth/email/verify`

**iOS 调用：**

```swift
let token = try await AuthService.login(email: "test@example.com", password: "123456")
// 或
let token = try await AuthService.loginWithTestAccount()
```

---

### POST /auth/login/apple

Apple 登录（当前为占位实现）。

**请求参数：**

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `identity_token` | string | 是 | Apple 返回的 identity token |
| `user_id` | string | 是 | Apple user identifier |

**响应示例：** 同 `/auth/email/verify`

**注意事项：**

后端目前未验证 Apple identity token 真实性，仅返回模拟用户。生产环境上线前需补充验证逻辑。

## 天气接口

### GET /weather/beijing

获取北京当前天气（后端代理 Open-Meteo）。

**注意**：当前 iOS 端已不再调用此接口，天气小组件保留在 Widget 扩展中作为占位，后续会替换为行情数据组件。

**认证：** 不需要登录。

**响应示例：**

```json
{
  "city": "北京",
  "temperature": 25.5,
  "description": "晴天",
  "updated_at": "2026-07-08T10:30:00"
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `city` | string | 城市名 |
| `temperature` | float | 当前温度（摄氏度） |
| `description` | string | 天气描述 |
| `updated_at` | string | 更新时间 |

**iOS 调用：**

```swift
let info = try await WeatherService.fetchBeijingWeather()
```

## 股票接口

> 股票接口均需登录，请求头中必须携带 `Authorization: Bearer {token}`。

### GET /stocks/quote/{code}

获取单只股票最新行情。

**路径参数：**

| 字段 | 类型 | 说明 |
|---|---|---|
| `code` | string | 股票代码，支持 `000001`、`000001.SZ`、`600519.SH`、`00700.HK` 等格式 |

**响应示例：**

```json
{
  "code": "000001",
  "name": "000001.SZ",
  "price": 12.35,
  "change_percent": 1.25,
  "updated_at": "2026-07-08T10:30:00"
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `code` | string | 用户传入的原始代码 |
| `name` | string | 标准化后的代码或股票名称（mock 模式下为中文名） |
| `price` | float | 最新收盘价 |
| `change_percent` | float | 涨跌幅百分比 |
| `updated_at` | string | 服务端响应时间 |

**iOS 调用：**

```swift
let quote = try await StockService.fetchQuote(code: "000001")
```

---

### GET /stocks/klines/{code}

获取股票 K 线数据。

**路径参数：**

| 字段 | 类型 | 说明 |
|---|---|---|
| `code` | string | 股票代码 |

**查询参数：**

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `period` | string | 否 | 周期：`D`（日）、`W`（周）、`M`（月）、`Y`（年），默认 `D` |
| `limit` | int | 否 | 返回条数，默认 30，最大 500 |

**响应示例：**

```json
[
  {
    "ts_code": "000001.SZ",
    "trade_date": "20240708",
    "period": "D",
    "open": 12.10,
    "high": 12.50,
    "low": 12.05,
    "close": 12.35,
    "volume": 123456.78,
    "amount": 1523456.78
  }
]
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `ts_code` | string | Tushare 标准化代码 |
| `trade_date` | string | 交易日（YYYYMMDD） |
| `period` | string | 周期 |
| `open` | float | 开盘价 |
| `high` | float | 最高价 |
| `low` | float | 最低价 |
| `close` | float | 收盘价 |
| `volume` | float? | 成交量 |
| `amount` | float? | 成交额 |

**iOS 调用：**

```swift
let klines = try await StockService.fetchKlines(code: "000001", period: .day, limit: 60)
```

---

### GET /stocks/watchlist

获取示例自选股列表。

**响应示例：**

```json
[
  {
    "code": "000001.SZ",
    "name": "000001.SZ",
    "price": 12.35,
    "change_percent": 1.25,
    "updated_at": "2026-07-08T10:30:00"
  },
  {
    "code": "600519.SH",
    "name": "600519.SH",
    "price": 1680.00,
    "change_percent": -0.50,
    "updated_at": "2026-07-08T10:30:00"
  }
]
```

**说明：**

当前后端返回固定的示例股票列表（平安银行、万科A、贵州茅台、腾讯控股）。后续会改为用户可自定义的自选股持久化。

**iOS 调用：**

```swift
let watchlist = try await StockService.fetchWatchlist()
```

---

### GET /stocks/sector-moneyflow

获取板块资金流排行（行业/概念）。

**认证：** 需要登录。

**查询参数：**

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `sector_type` | string | 否 | 板块类型：`industry`（行业，默认）/ `concept`（概念） |
| `trade_date` | string | 否 | 交易日期 `YYYYMMDD`，默认取数据库最新日期 |
| `sort_by` | string | 否 | 排序字段：`net_amount`（净流入，默认降序）、`pct_change`（涨跌幅降序）、`net_amount_asc`（净流入升序） |
| `limit` | int | 否 | 返回条数，默认 20，最大 100 |

**响应示例：**

```json
{
  "sectors": [
    {
      "ts_code": "881121.TI",
      "trade_date": "20260708",
      "name": "半导体",
      "lead_stock": "芯朋微",
      "close_price": 98.09,
      "pct_change": -0.66,
      "company_num": 180,
      "pct_change_stock": 16.80,
      "net_buy_amount": 2108.00,
      "net_sell_amount": 2041.00,
      "net_amount": 66.00
    }
  ],
  "trade_date": "20260708",
  "sector_type": "industry"
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `ts_code` | string | 板块代码，如 `881121.TI` |
| `trade_date` | string | 交易日期（YYYYMMDD） |
| `name` | string | 板块名称 |
| `lead_stock` | string | 龙头股 |
| `close_price` | float? | 领涨股/板块指数收盘价 |
| `pct_change` | float? | 板块涨跌幅% |
| `company_num` | int? | 成分股数量 |
| `pct_change_stock` | float? | 领涨股涨跌幅% |
| `net_buy_amount` | float? | 净流入-买入金额（亿元） |
| `net_sell_amount` | float? | 净流入-卖出金额（亿元） |
| `net_amount` | float? | 净流入金额（亿元） |

**iOS 调用：**

```swift
let rank = try await StockService.fetchSectorMoneyflow(sectorType: .industry, limit: 20)
```

**iOS 展示建议：**

- 行情页新增「板块资金流向」入口，默认展示行业净流入 TOP 20
- 支持切换「行业/概念」Tab
- 支持按净流入、涨跌幅排序
- 点击板块可跳转板块详情（后续可接成分股列表）

---

### GET /stocks/daily-basic/{code}

获取股票日线因子数据（PE、PB、换手率、市值等）。

**路径参数：**

| 字段 | 类型 | 说明 |
|---|---|---|
| `code` | string | 股票代码 |

**查询参数：**

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `limit` | int | 否 | 返回条数，默认 30，最大 500 |

**响应示例：**

```json
[
  {
    "ts_code": "000001.SZ",
    "trade_date": "20240708",
    "close": 12.35,
    "turnover_rate": 1.25,
    "turnover_rate_f": 1.10,
    "volume_ratio": 0.95,
    "pe": 6.78,
    "pe_ttm": 6.50,
    "pb": 0.85,
    "ps": 1.20,
    "ps_ttm": 1.15,
    "dv_ratio": 2.50,
    "dv_ttm": 2.60,
    "total_share": 1940602.00,
    "float_share": 1940602.00,
    "free_share": 1940602.00,
    "total_mv": 23966535.00,
    "circ_mv": 23966535.00
  }
]
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `ts_code` | string | Tushare 标准化代码 |
| `trade_date` | string | 交易日（YYYYMMDD） |
| `close` | float? | 收盘价 |
| `turnover_rate` | float? | 换手率 |
| `turnover_rate_f` | float? | 换手率（自由流通股） |
| `volume_ratio` | float? | 量比 |
| `pe` | float? | 市盈率 |
| `pe_ttm` | float? | 市盈率 TTM |
| `pb` | float? | 市净率 |
| `ps` | float? | 市销率 |
| `ps_ttm` | float? | 市销率 TTM |
| `dv_ratio` | float? | 股息率 |
| `dv_ttm` | float? | 股息率 TTM |
| `total_share` | float? | 总股本（万股） |
| `float_share` | float? | 流通股本（万股） |
| `free_share` | float? | 自由流通股本（万股） |
| `total_mv` | float? | 总市值（万元） |
| `circ_mv` | float? | 流通市值（万元） |

**iOS 调用：**

```swift
let factors = try await StockService.fetchDailyBasic(code: "000001", limit: 30)
```

**iOS 指标展示：**

股票详情页当前展示以下指标：

- 市盈率 PE / PE TTM
- 市净率 PB
- 市销率 PS
- 换手率
- 量比
- 总市值 / 流通市值
- 股息率 TTM

市值自动转换为 万/亿 单位显示。

## iOS 调用示例

```swift
// 1. 发送验证码
try await AuthService.sendEmailCode(email: "user@example.com")

// 2. 用户输入验证码后校验登录
let token = try await AuthService.verifyEmailCode(
    email: "user@example.com",
    code: "123456"
)

// 3. 登录成功后请求股票数据
let quote = try await StockService.fetchQuote(code: "000001")
let klines = try await StockService.fetchKlines(code: "000001", period: .week, limit: 30)
```

### 测试账号快速登录

```swift
let token = try await AuthService.loginWithTestAccount()
```

后端启动时会自动创建测试账号：

- 邮箱：`test@example.com`
- 密码：`123456`

> 说明：开发环境每次启动都会确保该测试账号存在且密码为 `123456`。如果之前通过验证码等方式创建过同名账号，后端会在启动时将其密码重置为 `123456`，以保证 iOS 测试登录始终可用。

### AuthService 接口

| 方法 | 说明 | iOS 调用示例 |
|---|---|---|
| `login(email:password:)` | 邮箱密码登录 | `try await AuthService.login(email: "test@example.com", password: "123456")` |
| `loginWithTestAccount()` | 测试账号一键登录 | `try await AuthService.loginWithTestAccount()` |
| `sendEmailCode(email:)` | 发送邮箱验证码 | `try await AuthService.sendEmailCode(email: "user@example.com")` |
| `verifyEmailCode(email:code:)` | 校验验证码并登录 | `try await AuthService.verifyEmailCode(email: "user@example.com", code: "123456")` |
| `restoreSession()` | 从 Keychain 恢复 token | `AuthService.restoreSession()` |
| `logout()` | 清除 Keychain 与内存 token | `AuthService.logout()` |

### Token 自动注入

`AuthService` 登录成功后会把 token 写入 `NetworkService`，后续请求会自动在 Header 中注入：

```
Authorization: Bearer {access_token}
```

## 错误码与处理

### HTTP 状态码

| 状态码 | 含义 | 常见场景 |
|---|---|---|
| 200 | 成功 | 正常返回 |
| 204 | 成功，无返回体 | 发送验证码 |
| 400 | 请求参数错误 | 验证码错误/过期、格式错误 |
| 401 | 未认证 | 缺少 token、token 失效、用户不存在 |
| 429 | 请求过于频繁 | 验证码发送过多 |
| 500 | 服务器内部错误 | 数据库异常、外部 API 失败 |

### iOS 统一错误类型

```swift
enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(String)
    case noData
    case unauthorized      // 401
    case serverError       // 500+
}
```

### iOS 端 401 处理

`NetworkService` 在收到任意 401 响应时会：

1. 立即清空内存中的 `authToken`。
2. 通过 `NotificationCenter` 发送 `sessionUnauthorized` 通知。
3. 抛出 `APIError.unauthorized`。

`ContentView` 监听该通知并调用 `AuthService.logout()`，清除 Keychain token 并回到登录页。因此业务代码无需手动处理 401 跳转登录页的逻辑。

### 处理建议

| 场景 | 建议 |
|---|---|
| `unauthorized` | 已由 `NetworkService` + `ContentView` 自动处理：清 token、回登录页 |
| `serverError` | 提示「服务器繁忙，请稍后再试」 |
| `httpError(400, ...)` | 展示服务端返回的 detail 信息 |
| `httpError(429, ...)` | 提示「请求过于频繁，请稍后再试」 |

## 模型映射参考

### Swift → 后端 JSON 字段

| Swift 字段 | JSON 字段 |
|---|---|
| `accessToken` | `access_token` |
| `tokenType` | `token_type` |
| `changePercent` | `change_percent` |
| `updatedAt` | `updated_at` |
| `tsCode` | `ts_code` |
| `tradeDate` | `trade_date` |

iOS 端模型已使用 `CodingKeys` 做好映射，调用时直接使用 Swift 命名即可。

## 后续接口规划

| 功能 | 预计接口 | 说明 |
|---|---|---|
| 添加自选股 | `POST /stocks/watchlist` | 用户自定义自选股 |
| 删除自选股 | `DELETE /stocks/watchlist/{code}` | 从用户列表中移除 |
| 获取自选股 | `GET /stocks/watchlist` | 替换为真实用户数据 |
| 日线因子 | `GET /stocks/daily-basic/{code}` | 已添加，PE/PB/换手率等 |
| 财务指标 | `GET /stocks/fina-indicator/{code}` | 季度财务数据 |
| 录入持仓 | `POST /portfolio` | 记录成本价、数量 |
| 修改持仓 | `PUT /portfolio/{code}` | 更新成本/数量 |
| 删除持仓 | `DELETE /portfolio/{code}` | 清仓 |
| 获取持仓 | `GET /portfolio` | 返回持仓与实时盈亏 |
| Apple 登录 | `POST /auth/login/apple` | 补充真实验证 |
| 行情提醒配置 | `POST /alerts` / `GET /alerts` | 股价/涨跌幅提醒 |

## 相关文件

- 后端路由：`trade_backend/app/api/v1/endpoints/`
- 后端模型：`trade_backend/app/schemas/`
- iOS 网络层：`YingPlus/Services/API/`
- iOS 股票模型：`YingPlus/Services/Stocks/StockModels.swift`
- iOS 股票服务：`YingPlus/Services/Stocks/StockService.swift`
