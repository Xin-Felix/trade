# 盈多多 / Ying+ - 项目状态与开发指南

> 更新时间：2026-07-08

---

## 当前已实现

### iOS App (trade_ios/YingPlus)

- **底部 Tab 导航**：首页、行情、组件、设置。
- **全局登录态**：`ContentView` 根据 `AuthService.restoreSession()` 决定展示登录页或主界面。
- **验证码登录**：`LoginView` 邮箱 → 获取验证码 → 输入 6 位验证码 → 自动注册/登录。
- **测试账号登录**：开发环境一键登录，方便快速体验。
- **Token 持久化**：`KeychainService` 安全保存 access token。
- **退出登录**：`SettingsView` 清除 Keychain 和内存 token。
- **首页 (HomeView)**：行情概览，展示大盘指数 + 自选股列表。
- **行情页 (MarketView)**：大盘指数 + 自选股列表，支持搜索股票代码。
- **行情详情 (StockDetailView)**：日/周/月/年 K 线图，支持捏合缩放、拖拽平移、长按十字光标显示 OHLC；展示股票指标（PE/PB/PS/换手率/量比/市值/股息率）。
- **通用网络层 (NetworkService)**：
  - 支持 GET/POST/PUT/DELETE/PATCH。
  - 自动注入 Bearer Token。
  - 统一错误处理 (`APIError`)。
  - 支持 204 No Content 响应（`requestVoid`）。
- **股票服务 (StockService)**：接入后端真实股票/K 线数据。
- **图标**：紫色背景白色 W 的 App Icon。

### Widget 扩展 (trade_ios/YingPlusWidget)

- **时钟组件**：每分钟刷新，显示当前时间。
- **天气组件**：保留旧天气组件文件，后续替换为行情数据组件。
- Widget 扩展已正常嵌入主 App Target（`Embed Foundation Extensions`）。

### 后端 (trade_backend)

> 后端为独立 Git 仓库，位于 `trade_backend/`。

- **FastAPI 分层架构**：
  - `app/api/v1/endpoints/`：路由
  - `app/core/`：配置、安全、依赖
  - `app/db/`：数据库（MySQL + SQLAlchemy）
  - `app/models/`：ORM 模型
  - `app/schemas/`：Pydantic 模型
  - `app/services/`：业务逻辑
  - `app/utils/`：工具函数
  - `tests/`：接口测试
  - `alembic/`：数据库迁移
- **邮箱验证码登录**：
  - `POST /api/v1/auth/email/code`：发送验证码邮件
  - `POST /api/v1/auth/email/verify`：校验验证码，新用户自动注册并登录
- **兼容登录**：`POST /api/v1/auth/login/email` 保留密码登录（测试账号用）
- **认证保护**：股票接口统一依赖 `get_current_user`
- **SMTP 邮件**：接入 QQ 邮箱 SMTP 发送验证码
- **股票数据**：接入 Tushare，日线从 Tushare 拉取并落库；周/月/年线由日线聚合
- **Docker 一键启动**：`docker-compose.yml` + `Dockerfile` 启动 MySQL + backend

### 项目结构

- `trade_ios/`：iOS App + Widget 扩展 + 文档（当前 Git 仓库）
- `trade_backend/`：FastAPI 后端（独立 Git 仓库）

### 文档

- `trade_ios/README.md`：项目简介、结构、运行方式
- `trade_ios/Docs/PRD.md`：产品方向与阶段规划
- `trade_ios/Docs/Architecture.md`：整体架构与数据流
- `trade_ios/Docs/API.md`：后端接口与 iOS 调用示例
- `trade_ios/Docs/PROJECT_STATUS.md`：项目状态与开发指南
- `trade_backend/README.md`：后端运行与接口说明

---

## 关键决策

1. **SwiftUI + WidgetKit**：原生 iOS 方案，HTML/JS 不能用于 WidgetKit 渲染。
2. **Python + FastAPI 后端**：适合金融数据处理，生态丰富（akshare/tushare）。
3. **邮箱验证码登录**：无需密码，新用户自动注册，降低使用门槛。
4. **Token 持久化到 Keychain**：App 重启后自动恢复登录态。
5. **前后端目录拆分**：iOS 和后端分别放在 `trade_ios/` 和 `trade_backend/`，独立 Git 仓库管理。
6. **Apple 登录延后**：因 Apple Developer 账号 $100 年费，待 App 成熟后再接入。

---

## 已知问题 / 注意事项

- **后端 `.env` 包含敏感信息**：已加入 `.gitignore`，请勿提交到仓库。
- **Docker 镜像源**：如本地 Docker 配置了不可用的镜像加速器，可能导致 `docker compose up` 拉取镜像失败。
- **Tushare Token**：股票真实数据需配置 `TUSHARE_TOKEN`。
- **Apple 登录**：当前为 UI 占位，后端 `app/services/auth_service.py` 中需补充 identity token 验证。
- **数据库**：开发环境启动时自动建表；生产环境建议使用 Alembic 管理迁移。
- **后端地址**：开发环境默认配置为 `http://172.17.82.33:8000`，模拟器调试时可改为 `http://127.0.0.1:8000`。
- **废弃文件**：`trade_ios/StockModels.swift` 为旧版模型草稿，可安全删除，当前使用 `YingPlus/Services/Stocks/StockModels.swift`。

---

## 下一步建议

### 近期

1. 自选股管理：前端增删改 + 后端持久化。
2. 持仓盈亏：用户可录入持仓，展示实时盈亏。
3. 行情提醒小组件：把股票数据展示到桌面小组件。

### 中期

4. Apple 登录。
5. 推送通知（股价提醒）。
6. 多设备数据同步。

### 远期

7. App Store 上架准备。

---

## 如何继续开发

### 启动 iOS App

```bash
cd /Users/huangxin/Desktop/trade/trade_ios
open YingPlus.xcodeproj
# 选择模拟器，Cmd+R
```

### 启动后端

方式一（推荐）：

```bash
cd /Users/huangxin/Desktop/trade/trade_backend
docker compose up -d
```

方式二（本地 Python）：

```bash
cd /Users/huangxin/Desktop/trade/trade_backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

访问：http://127.0.0.1:8000/docs

---

## Git 状态

- `trade_ios`：当前 Git 仓库，`Backend/` 目录已移除并拆分到独立仓库
- `trade_backend`：独立 Git 仓库，`.env` 已忽略
- 两个仓库都尚未配置 remote，需手动添加后 push
